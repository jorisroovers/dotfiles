---
name: github
description: Read GitHub PR, CI, and code-review state reliably with the `gh` CLI. Use when an agent needs to answer "did CI pass", "has the review bot reviewed the current commit", "is anything unresolved", or "is a review even coming" for a pull request, and when writing waits or polls against GitHub without stalling.
---

# GitHub PR and review state

Use this skill to read pull request state correctly with `gh`. It covers the
API-level mechanics: which endpoint carries which signal, how to pin a query to
the current head commit, and the predicates that silently never match. Policy
about *when* to wait and *what* blocks a merge belongs to the workflow that
calls this skill (see the `pr-loop` skill for the autonomous PR cycle).

Throughout, `OWNER/REPO` is the repository and `<N>` the PR number. Inside a
checkout you can omit `-R OWNER/REPO`; outside one, always pass it. To resolve
them explicitly:

```bash
read -r OWNER REPO <<<"$(gh repo view --json owner,name -q '"\(.owner.login) \(.name)"')"
```

## Always pin to the current head commit

A result from before the last push is not a result for the current code. Fetch
the head SHA first and conjoin it into every "has this been checked" query:

```bash
SHA=$(gh pr view <N> --json headRefOid -q .headRefOid)
```

## CI checks

CI is fast (typically ~3 minutes), so blocking on it once is fine:

```bash
gh pr checks <N> --watch --fail-fast --interval 20
```

Exit codes: `0` all passed, `1` a check failed, `8` still pending. The same
exit codes apply to the non-blocking snapshot `gh pr checks <N>`. For a grouped
summary:

```bash
gh pr view <N> --json statusCheckRollup \
  -q '[.statusCheckRollup[]] | group_by(.conclusion // .state)[] | "\(.[0].conclusion // .[0].state): \(length)"'
```

## The three signal channels of a review bot

A Codex review can land in **three** different places, not two. Checking only
reviews, or only reviews plus comments, will misread real outcomes:

1. **Findings** → a *review* object plus inline review threads.
2. **Clean, verbose** → an *issue comment* starting
   `Codex Review: Didn't find any major issues`, plus a 👍 reaction.
3. **Clean, silent** → **a 👍 reaction only**, with zero reviews and zero
   comments on the PR.

Case 3 is indistinguishable from "no review bot is configured here" unless you
query reactions. It has caused a real misread: a PR whose only trace of a
completed clean review was a `+1` reaction was treated as never reviewed.

Both bot body shapes embed ``**Reviewed commit:** `<10-char sha>` ``, which
lets one predicate cover reviews and comments together.

## Reactions: "is a review even coming?"

Reactions live on a separate REST endpoint and appear in neither the reviews
nor the comments lists, nor in the GraphQL query below. Checking them is the
only way to see a clean review that left no other trace:

```bash
gh api repos/OWNER/REPO/issues/<N>/reactions \
  -q '.[] | select(.user.login|test("codex";"i")) | "\(.content) \(.created_at)"'
```

- `+1` → the bot finished and found nothing. This may be the *only* signal:
  no review, no comment. Treat it as a completed clean review and proceed.
- no reaction and no result, past a grace window → no review is coming.

There is no observed "in progress" signal, so **time is the only thing that
separates "still working" from "never coming"** — which is exactly why the
grace window below exists rather than a smarter predicate. Check reactions
early anyway, right after opening the PR or requesting a re-review: a `+1`
already sitting there ends the wait immediately.

## One query for the whole review gate

This answers "did the bot review the current head, and is anything unresolved"
in a single call:

```bash
read -r OWNER REPO <<<"$(gh repo view --json owner,name -q '"\(.owner.login) \(.name)"')"
SHA=$(gh pr view <N> --json headRefOid -q .headRefOid)
gh api graphql -F owner="$OWNER" -F repo="$REPO" -F pr=<N> -f query='
query($owner:String!,$repo:String!,$pr:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$pr){
  headRefOid
  reviews(last:30){nodes{author{login} commit{oid} submittedAt}}
  comments(last:30){nodes{author{login} createdAt body}}
  reviewThreads(first:100){nodes{id isResolved comments(first:1){nodes{author{login} path}}}}
}}}' | jq -r --arg sha "$SHA" '
.data.repository.pullRequest as $p
| ([$p.reviews.nodes[] | select(.author.login=="chatgpt-codex-connector" and .commit.oid==$sha)]
   + [$p.comments.nodes[] | select(.author.login=="chatgpt-codex-connector" and (.body | test("Reviewed commit:\\*\\* `" + $sha[0:10])))]) as $hits
| [$p.reviewThreads.nodes[] | select(.isResolved | not)] as $open
| "sha=\($sha[0:10]) codex_results=\($hits|length) unresolved_threads=\($open|length)",
  ($open[] | "  OPEN \(.id) \(.comments.nodes[0].author.login) \(.comments.nodes[0].path)")'
```

`codex_results>=1` with `unresolved_threads=0` is the green state. The thread
IDs printed are exactly the node IDs `resolveReviewThread` takes.

`codex_results=0` is **not** automatically "wait". It means one of the three
reaction cases above, and this query cannot tell them apart — check reactions.

## Predicates that silently never match

- **The bot login differs by API.** REST reports
  `chatgpt-codex-connector[bot]`; GraphQL `author.login` reports
  `chatgpt-codex-connector` with no `[bot]` suffix. A predicate copied from one
  API to the other matches nothing and reports a clean or absent review
  forever. Use `test("codex";"i")` when you want one predicate for both.
- **Filtering reviews by commit SHA alone matches your own replies.** Inline
  replies you post are review objects on the same commit, so a bare
  `select(.commit_id==$sha)` returns your own reviews and any wait exits
  immediately. Always conjoin the author check.
- **Older reviews look like fresh ones.** Without the `headRefOid` pin, a review
  from before the last push reads as a current result.

## Waiting without stalling

A foreground shell call is killed at ~600s. Never write an unbounded
`until ...; do sleep 30; done` wait: it gets backgrounded, burns turns, and
reports nothing useful. Review bots are slow (8–15 minutes after a re-review
request) — do other work instead of blocking on them. When a poll is genuinely
needed, bound it:

```bash
deadline=$((SECONDS+480))
until <ready-check>; do
  (( SECONDS >= deadline )) && { echo "not ready yet"; exit 1; }
  sleep 30
done
```

The loop exits non-zero well before the harness timeout; re-invoke it after
doing other work rather than extending the deadline.

**No review at all is a normal outcome.** Docs-only PRs, bot outages, and PRs
the bot simply does not pick up produce no review ever. Apply a grace window of
roughly 10 minutes from PR open or re-review request; if there is no reaction
and no result by then, conclude no review is coming and proceed. Re-requesting
once is reasonable; a second re-request that also produces nothing is
confirmation, not a reason to keep waiting.

## Raw REST fallbacks

When you want the unaggregated lists:

```bash
gh api repos/OWNER/REPO/pulls/<N>/reviews  -q '.[] | "\(.user.login) \(.commit_id[0:10]) \(.state)"'
gh api repos/OWNER/REPO/pulls/<N>/comments -q '.[] | "\(.user.login) \(.path):\(.line) \(.body[0:80])"'
gh api repos/OWNER/REPO/issues/<N>/comments -q '.[] | "\(.user.login) \(.created_at) \(.body[0:80])"'
```

Remember the `[bot]` suffix applies to `user.login` on all three.
