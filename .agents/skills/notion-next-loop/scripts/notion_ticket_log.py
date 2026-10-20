#!/usr/bin/env python3
"""Newest-first AI work result log for Notion TODO tickets."""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

RESULT_HEADING_RE = re.compile(r"(?m)^##[ \t]+AI work result(?:[ \t].*)?$")
DATE_RE = re.compile(r"(\d{4}-\d{2}-\d{2})")
UNSAFE_MARKDOWN_RE = re.compile(r"<(?:page|database|unknown)\b", re.I)
DEFAULT_STATUSES = ("Next", "Human Review")
# Blank lines above a divider at the top of the page: a ready-made slot for the
# human's next feedback, so they do not have to create spacing themselves.
FEEDBACK_PLACEHOLDER = "<empty-block/>\n<empty-block/>\n<empty-block/>\n---\n"
LEADING_DIVIDER_RE = re.compile(r"\A(?:[ \t]*(?:<empty-block/>)?[ \t]*\n)*[ \t]*---[ \t]*(?:\n|\Z)")


def fail(message: str) -> None:
    print(f"notion-todo: {message}", file=sys.stderr)
    raise SystemExit(1)


def find_config(start: str | None = None) -> Path:
    directory = Path(start or os.environ.get("NOTION_TODO_ROOT") or os.getcwd()).resolve()
    for path in [directory, *directory.parents]:
        candidate = path / ".notion-todo.json"
        if candidate.is_file():
            return candidate
    fail("could not find .notion-todo.json; run this from the repository or set NOTION_TODO_ROOT")


def load_config(start: str | None = None) -> dict[str, Any]:
    config_path = find_config(start)
    return json.loads(config_path.read_text(encoding="utf-8"))


def ntn_api(path: str, *args: str, data: dict[str, Any] | None = None) -> dict[str, Any]:
    cmd = ["ntn", "api", path, *args]
    tmp_path = None
    try:
        if data is not None:
            tmp = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8")
            tmp_path = tmp.name
            json.dump(data, tmp)
            tmp.close()
            cmd.extend(["--data", f"@{tmp_path}"])
        result = subprocess.run(cmd, capture_output=True, text=True)
    finally:
        if tmp_path:
            os.unlink(tmp_path)
    if result.returncode != 0:
        err = (result.stderr or result.stdout or "ntn api failed").strip()
        fail(err)
    return json.loads(result.stdout) if result.stdout.strip() else {}


def ntn_query(data_source_id: str, filter_obj: dict[str, Any], start_cursor: str | None = None) -> dict[str, Any]:
    cmd = [
        "ntn",
        "datasources",
        "query",
        data_source_id,
        "--limit",
        "100",
        "--json",
        "--filter",
        json.dumps(filter_obj),
    ]
    if start_cursor:
        cmd.extend(["--start-cursor", start_cursor])
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        err = (result.stderr or result.stdout or "ntn datasources query failed").strip()
        fail(err)
    return json.loads(result.stdout)


def get_markdown(page_id: str) -> dict[str, Any]:
    return ntn_api(f"v1/pages/{page_id}/markdown")


def insert_at_start(page_id: str, content: str) -> dict[str, Any]:
    body = content.replace("\r\n", "\n")
    if not body.endswith("\n"):
        body += "\n"
    if not body.endswith("\n\n"):
        body += "\n"
    return ntn_api(
        f"v1/pages/{page_id}/markdown",
        "-X",
        "PATCH",
        data={
            "type": "insert_content",
            "insert_content": {
                "content": body,
                "position": {"type": "start"},
            },
        },
    )


def replace_content(page_id: str, markdown: str) -> dict[str, Any]:
    return ntn_api(
        f"v1/pages/{page_id}/markdown",
        "-X",
        "PATCH",
        data={
            "type": "replace_content",
            "replace_content": {"new_str": markdown},
        },
    )


def starts_with_divider(markdown: str) -> bool:
    """True when the page opens with (optional blank lines and) a divider.

    That is an unused feedback placeholder, so a new result does not need its
    own trailing divider to stay separated from what follows.
    """
    return bool(LEADING_DIVIDER_RE.match(markdown.replace("\r\n", "\n")))


def build_result_markdown(content: str, existing: str | None, placeholder: bool = True) -> str:
    """Markdown to insert at the start of the page for one AI work result.

    Layout (newest first): feedback placeholder, divider, result, then a
    divider separating it from whatever human feedback or older result was at
    the top. The trailing divider is skipped when the page is empty or already
    opens with a divider (an unused placeholder), to avoid double rules.
    """
    body = content.replace("\r\n", "\n").strip("\n")
    if not placeholder:
        return body + "\n\n"
    parts = [FEEDBACK_PLACEHOLDER, body, "\n"]
    rest = existing or ""
    if rest.strip() and not starts_with_divider(rest):
        parts.append("---\n")
    return "".join(parts)


def upload_file(path: Path) -> str:
    content_type = "text/markdown" if path.suffix.lower() in {".md", ".markdown"} else "text/plain"
    with path.open("rb") as handle:
        result = subprocess.run(
            ["ntn", "files", "create", "--filename", path.name, "--content-type", content_type, "--json"],
            stdin=handle,
            capture_output=True,
        )
    if result.returncode != 0:
        fail((result.stderr or result.stdout or b"ntn files create failed").decode(errors="replace").strip())
    upload = json.loads(result.stdout)
    if upload.get("status") != "uploaded" or not upload.get("id"):
        fail(f"file upload for {path.name} did not complete")
    return upload["id"]


def top_children(page_id: str) -> list[dict[str, Any]]:
    payload = ntn_api(f"v1/blocks/{page_id}/children?page_size=100")
    return payload.get("results") or []


def block_text(block: dict[str, Any]) -> str:
    data = block.get(block.get("type") or "") or {}
    return "".join(part.get("plain_text") or "" for part in data.get("rich_text") or [])


def section_anchor(children: list[dict[str, Any]], old_first_id: str | None) -> str | None:
    """Last block of the newly prepended result section (before its closing divider)."""
    start = None
    for index, block in enumerate(children):
        if block.get("type") == "heading_2" and block_text(block).startswith("AI work result"):
            start = index
            break
    if start is None:
        return None
    end = len(children)
    for index in range(start + 1, len(children)):
        if children[index].get("id") == old_first_id:
            end = index
            break
    section = children[start:end]
    while len(section) > 1 and section[-1].get("type") == "divider":
        section.pop()
    return section[-1].get("id")


def attach_files(page_id: str, paths: list[Path], old_first_id: str | None) -> int:
    anchor = section_anchor(top_children(page_id), old_first_id)
    if anchor is None:
        fail("could not find the new AI work result heading to attach files under")
    children = []
    for path in paths:
        upload_id = upload_file(path)
        children.append(
            {
                "object": "block",
                "type": "file",
                "file": {
                    "type": "file_upload",
                    "file_upload": {"id": upload_id},
                    "caption": [{"type": "text", "text": {"content": path.name}}],
                },
            }
        )
    ntn_api(
        f"v1/blocks/{page_id}/children",
        "-X",
        "PATCH",
        data={"children": children, "position": {"type": "after_block", "after_block": {"id": anchor}}},
    )
    return len(children)


def split_result_log(markdown: str) -> tuple[str, list[str]] | None:
    text = markdown.replace("\r\n", "\n")
    matches = list(RESULT_HEADING_RE.finditer(text))
    if not matches:
        return None
    prefix = text[: matches[0].start()]
    results: list[str] = []
    for i, match in enumerate(matches):
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        results.append(text[match.start() : end])
    return prefix, results


def result_date(block: str) -> str:
    first = block.split("\n", 1)[0]
    match = DATE_RE.search(first)
    return match.group(1) if match else ""


def ensure_block(block: str) -> str:
    text = block.replace("\r\n", "\n")
    if not text.endswith("\n"):
        text += "\n"
    if not text.endswith("\n\n"):
        text += "\n"
    return text


def is_oldest_first(prefix: str, results: list[str]) -> bool:
    return bool(prefix.strip()) and bool(results)


def reorder_markdown(markdown: str) -> str | None:
    parsed = split_result_log(markdown)
    if parsed is None:
        return None
    prefix, results = parsed
    if not is_oldest_first(prefix, results):
        return None
    indexed = list(enumerate(results))
    ordered = [
        block
        for _, block in sorted(
            indexed,
            key=lambda item: (result_date(item[1]), item[0]),
            reverse=True,
        )
    ]
    parts = [ensure_block(block) for block in ordered]
    prefix_text = prefix.lstrip("\n")
    if prefix_text.strip():
        if not prefix_text.endswith("\n"):
            prefix_text += "\n"
        parts.append(prefix_text)
    return "".join(parts).rstrip() + "\n"


def markdown_is_unsafe(payload: dict[str, Any]) -> str | None:
    if payload.get("truncated"):
        return "truncated markdown"
    if payload.get("unknown_block_ids"):
        return "unknown_block_ids"
    markdown = payload.get("markdown") or ""
    if UNSAFE_MARKDOWN_RE.search(markdown):
        return "child page/database or unknown blocks"
    return None


def page_title(page: dict[str, Any]) -> str:
    for value in (page.get("properties") or {}).values():
        if value.get("type") == "title":
            return "".join(part.get("plain_text") or "" for part in value.get("title") or [])
    return ""


def page_status(page: dict[str, Any], status_property: str) -> str:
    field = (page.get("properties") or {}).get(status_property) or {}
    return (field.get("status") or {}).get("name") or (field.get("select") or {}).get("name") or ""


def iter_status_pages(data_source_id: str, status_property: str, status: str) -> list[dict[str, Any]]:
    pages: list[dict[str, Any]] = []
    cursor = None
    while True:
        payload = ntn_query(
            data_source_id,
            {"property": status_property, "status": {"equals": status}},
            start_cursor=cursor,
        )
        pages.extend(payload.get("results") or [])
        if not payload.get("has_more"):
            break
        cursor = payload.get("next_cursor")
        if not cursor:
            break
    return pages


def classify_page(page_id: str) -> dict[str, str]:
    payload = get_markdown(page_id)
    unsafe = markdown_is_unsafe(payload)
    if unsafe:
        return {"action": "skip", "reason": unsafe}
    markdown = payload.get("markdown") or ""
    parsed = split_result_log(markdown)
    if parsed is None:
        return {"action": "skip", "reason": "no AI work result heading"}
    reordered = reorder_markdown(markdown)
    if reordered is None:
        return {"action": "skip", "reason": "already newest-first or not oldest-first"}
    if reordered == markdown:
        return {"action": "skip", "reason": "no change"}
    return {"action": "reorder", "reason": "oldest-first result log", "markdown": reordered}


def emit_tsv(row: list[str]) -> None:
    print("\t".join(row))


def run_result(
    page_id: str,
    content: str | None,
    placeholder: bool = True,
    attachments: list[str] | None = None,
) -> None:
    if content is None:
        if sys.stdin.isatty():
            fail("result requires --content or stdin")
        content = sys.stdin.read()
    if not content.strip():
        fail("result content is empty")
    paths = [Path(item).expanduser() for item in attachments or []]
    for path in paths:
        if not path.is_file():
            fail(f"attachment not found: {path}")
    existing = get_markdown(page_id).get("markdown") or "" if placeholder else None
    old_first_id = None
    if paths:
        children = top_children(page_id)
        old_first_id = children[0].get("id") if children else None
    payload = insert_at_start(page_id, build_result_markdown(content, existing, placeholder))
    attached = attach_files(page_id, paths, old_first_id) if paths else 0
    row = [payload.get("id") or page_id, "prepended", payload.get("object") or ""]
    if attached:
        row.append(f"attached={attached}")
    emit_tsv(row)


def run_reorder(page_id: str | None, statuses: list[str], dry_run: bool) -> None:
    if page_id:
        decision = classify_page(page_id)
        emit_tsv([page_id, decision["action"], decision["reason"]])
        if decision["action"] == "reorder" and not dry_run:
            replace_content(page_id, decision["markdown"])
        return

    config = load_config()
    data_source_id = config["dashboard"]["data_source_id"]
    status_property = config["workflow"]["status_property"]
    board = config.get("dashboard", {}).get("name") or data_source_id
    seen: set[str] = set()
    for status in statuses:
        try:
            pages = iter_status_pages(data_source_id, status_property, status)
        except SystemExit as exc:
            emit_tsv([board, status, "error", str(exc)])
            continue
        for page in pages:
            pid = page.get("id") or ""
            if not pid or pid in seen:
                continue
            seen.add(pid)
            title = page_title(page)
            live_status = page_status(page, status_property) or status
            try:
                decision = classify_page(pid)
            except SystemExit as exc:
                emit_tsv([pid, title, live_status, "error", str(exc)])
                continue
            emit_tsv([pid, title, live_status, decision["action"], decision["reason"]])
            if decision["action"] == "reorder" and not dry_run:
                replace_content(pid, decision["markdown"])


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(prog="notion-todo")
    sub = parser.add_subparsers(dest="cmd", required=True)

    result_cmd = sub.add_parser("result", help="Prepend markdown at the start of a page")
    result_cmd.add_argument("page_id")
    result_cmd.add_argument("--content", default=None)
    result_cmd.add_argument(
        "--attach",
        action="append",
        default=None,
        metavar="PATH",
        help="Upload a local artifact and attach it as a file block in the new section (repeatable)",
    )
    result_cmd.add_argument(
        "--no-placeholder",
        action="store_true",
        help="Do not add the blank feedback slot and dividers around the result",
    )

    reorder_cmd = sub.add_parser("reorder-results", help="Move oldest-first AI work results to the top")
    reorder_cmd.add_argument("--page", default=None)
    reorder_cmd.add_argument("--dry-run", action="store_true")
    reorder_cmd.add_argument("--status", action="append", default=None)

    args = parser.parse_args(argv)
    if args.cmd == "result":
        run_result(args.page_id, args.content, not args.no_placeholder, args.attach)
        return
    statuses = args.status or list(DEFAULT_STATUSES)
    run_reorder(args.page, statuses, args.dry_run)


if __name__ == "__main__":
    main()
