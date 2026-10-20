#!/usr/bin/env python3
import unittest

from notion_ticket_log import (
    FEEDBACK_PLACEHOLDER,
    build_result_markdown,
    reorder_markdown,
    section_anchor,
    split_result_log,
    starts_with_divider,
)


class ReorderMarkdownTests(unittest.TestCase):
    def test_skips_pages_without_results(self) -> None:
        self.assertIsNone(reorder_markdown("Just the original request.\n"))

    def test_moves_single_trailing_result_to_start(self) -> None:
        md = (
            "Original dictation here.\n"
            "\n"
            "## AI work result — 2026-09-16\n"
            "Oldest outcome.\n"
        )
        got = reorder_markdown(md)
        self.assertEqual(
            got,
            "## AI work result — 2026-09-16\n"
            "Oldest outcome.\n"
            "\n"
            "Original dictation here.\n",
        )

    def test_newest_result_comes_first(self) -> None:
        md = (
            "Original request.\n"
            "\n"
            "## AI work result — 2026-09-16\n"
            "First loop.\n"
            "\n"
            "## AI work result — 2026-09-17\n"
            "Second loop.\n"
        )
        got = reorder_markdown(md)
        self.assertTrue(got.startswith("## AI work result — 2026-09-17\n"))
        self.assertIn("Original request.\n", got)
        self.assertLess(got.index("2026-09-17"), got.index("2026-09-16"))
        self.assertGreater(got.index("Original request."), got.index("2026-09-16"))

    def test_same_date_later_section_is_newer(self) -> None:
        md = (
            "Ticket body.\n"
            "## AI work result — 2026-09-17\n"
            "Morning.\n"
            "## AI work result — 2026-09-17\n"
            "Evening.\n"
        )
        got = reorder_markdown(md)
        self.assertLess(got.index("Evening."), got.index("Morning."))

    def test_skips_already_newest_first(self) -> None:
        md = (
            "## AI work result — 2026-09-17\n"
            "New.\n"
            "\n"
            "## AI work result — 2026-09-16\n"
            "Old.\n"
            "\n"
            "Original request.\n"
        )
        self.assertIsNone(reorder_markdown(md))

    def test_split_keeps_human_notes_with_preceding_result(self) -> None:
        md = (
            "Original.\n"
            "## AI work result — 2026-09-16\n"
            "A.\n"
            "---\n"
            "Human follow-up.\n"
            "## AI work result — 2026-09-17\n"
            "B.\n"
        )
        prefix, results = split_result_log(md)
        self.assertEqual(prefix, "Original.\n")
        self.assertEqual(len(results), 2)
        self.assertIn("Human follow-up.", results[0])


RESULT = "## AI work result — 2026-09-18\n**Outcome:** done.\n"


class BuildResultMarkdownTests(unittest.TestCase):
    def test_placeholder_divider_then_result_then_divider(self) -> None:
        got = build_result_markdown(RESULT, "Human feedback.\n---\n## AI work result — 2026-09-17\n")
        self.assertEqual(got, FEEDBACK_PLACEHOLDER + RESULT + "---\n")

    def test_no_trailing_divider_on_empty_page(self) -> None:
        self.assertEqual(build_result_markdown(RESULT, ""), FEEDBACK_PLACEHOLDER + RESULT)

    def test_unused_placeholder_is_not_doubled(self) -> None:
        existing = FEEDBACK_PLACEHOLDER + "## AI work result — 2026-09-17\nOld.\n"
        self.assertEqual(build_result_markdown(RESULT, existing), FEEDBACK_PLACEHOLDER + RESULT)

    def test_no_placeholder_is_legacy_prepend(self) -> None:
        self.assertEqual(build_result_markdown(RESULT, None, placeholder=False), RESULT + "\n")

    def test_starts_with_divider(self) -> None:
        self.assertTrue(starts_with_divider("---\nx"))
        self.assertTrue(starts_with_divider("<empty-block/>\n\n---\n"))
        self.assertFalse(starts_with_divider("Feedback\n---\n"))
        self.assertFalse(starts_with_divider("## AI work result — 2026-09-17\n"))


def block(block_id: str, kind: str, text: str = "") -> dict:
    return {"id": block_id, "type": kind, kind: {"rich_text": [{"plain_text": text}]}}


class SectionAnchorTests(unittest.TestCase):
    def test_anchor_is_last_block_before_closing_divider(self) -> None:
        children = [
            block("e1", "paragraph"),
            block("d1", "divider"),
            block("h", "heading_2", "AI work result — 2026-09-18"),
            block("p1", "paragraph", "Outcome"),
            block("p2", "paragraph", "Artifact"),
            block("d2", "divider"),
            block("old", "paragraph", "Human feedback"),
        ]
        self.assertEqual(section_anchor(children, "old"), "p2")

    def test_anchor_on_empty_page(self) -> None:
        children = [block("h", "heading_2", "AI work result — 2026-09-18"), block("p1", "paragraph")]
        self.assertEqual(section_anchor(children, None), "p1")

    def test_no_heading(self) -> None:
        self.assertIsNone(section_anchor([block("p", "paragraph", "x")], None))


if __name__ == "__main__":
    unittest.main()
