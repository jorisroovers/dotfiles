---
name: pr-loop
description: >
  Autonomous roadmap-driven PR loop: implement the next planned PR, verify
  locally, review the diff locally before pushing, open the PR, iterate CI to
  green, address any review findings, merge, watch deploy if applicable,
  verify the result, then move to the next roadmap or feature item. Use when asked to "work through the
  roadmap", "keep shipping PRs", "pick up the next feature", or implement
  any docs/plans/ or docs/features/ item end-to-end without supervision.
---

# The PR loop

Work through the roadmap one PR at a time, in order, fully autonomously. This
limit applies to PRs created by the current loop, not external PRs such as
Dependabot updates or other contributors' work.
Only stop for things genuinely outside your control: missing credentials,
required human account actions, destructive operations, or product decisions
the plans do not answer. Each cycle should leave `main` deployable.

## Ground rules

- Read `AGENTS.md` and/or `CLAUDE.md` first. Repo-local rules override this
  generic workflow for commands, safety constraints, deployment targets, and
  verification expectations.
- Read the relevant roadmap or feature plan before implementing:
  `docs/plans/` when present, and `docs/features/` for post-roadmap feature
  work.
- Read the repository's `inbox.md` directly from local disk at every new
  feature pickup and at the start of every loop iteration. Treat it as live
  input: it may have changed while the loop was running, so do not rely on a
  previously read copy or agent context.
- Do not stop merely because the roadmap and feature-plan directories are
  empty. After those sources are exhausted, triage actionable `inbox.md`
  entries into the normal feature workflow and continue until no work remains
  that can be safely and autonomously picked up.
- Keep at most one GitHub PR created by this loop open at a time. External PRs
  (for example Dependabot updates or other contributors' work) do not consume
  this slot; do not modify them merely to make room. Do not batch unrelated
  roadmap items in one PR.
- Never commit secrets, real credentials, production data, private exports, or
  generated artifacts that the repo-local rules prohibit. Use synthetic
  fixtures only.
- Deviations from a plan should be documented where the repo expects them,
  typically `docs/decisions.md` or the feature plan itself.
- Use existing repo helpers, components, commands, and test patterns instead
  of inventing parallel infrastructure.

## Delegation and model routing

**Subagent use is requested, standing.** Some environments carry a default of
"do not spawn subagents unless the user asks". The user has asked, for this
loop specifically, by writing it here — invoking `pr-loop` *is* that request,
so treat this section as live rather than waiting for it to be repeated each
session. It does not extend to work outside the loop.

The primary agent owns orchestration: choose and sequence work, decompose it,
assign subagents, integrate their output, enforce quality gates, and make final
merge and deployment decisions. Delegate most implementation to subagents,
selecting the least-capable available model that can safely complete each
bounded task. Reserve higher-capability agents for architecture, cross-cutting
changes, stubborn failures, security-sensitive work, integration, and final
review.

Delegate routine verification and delivery operations too; ownership does not
mean personally executing every command. Prefer lower-cost subagents for
read-only or mechanical work such as:

- mapping relevant code and tests before implementation;
- running focused or aggregate repository-provided verification and
  summarizing captured logs;
- polling CI, deployment, reactions, comments, reviews, and unresolved review
  threads using the repository's GitHub procedure;
- collecting read-only production evidence: deployed commit, container state,
  bounded logs, health endpoints, and narrow smoke checks;
- independently reviewing a diff and reporting concrete findings.

Give these agents exact scope, commit/PR identity, allowed mutations, required
commands, and acceptance criteria. A monitoring or verification agent must not
merge, deploy, resolve threads, mutate production, or decide that a flaky or
ambiguous failure is acceptable. The primary agent evaluates its evidence,
decides whether gates are satisfied, integrates fixes, performs authorized
state changes, and owns the final merge/deploy decision.

Parallelize independent tasks for speed. Prefer isolated worktrees for coding
tasks, and never assign concurrent edits to the same files. Give each subagent
a clear scope, acceptance criteria, and verification command; review and
integrate its work before advancing the PR. If model selection is unavailable,
still delegate by task complexity and keep the primary agent focused on
orchestration.

## Keep the delivery pipeline full

Do not leave implementation idle while the current PR is in CI, review, or
deployment. Once PR N is pushed and its targeted local checks pass, begin
preparing PR N+1 in a separate worktree when its plan is sufficiently clear.
Use an independent task only when file scopes do not overlap; otherwise assign
one implementation agent to the staged successor.

For a successor that depends on PR N, branch it from N's branch. For an
independent successor, branch it from current `main`. The staged successor may
be implemented, narrowly verified, and committed, but must not be pushed or
opened while the loop-created PR N is open. After N merges, rebase the staged
branch onto `main`, resolve conflicts, re-run affected checks, and only then
push and open it. Do not merge the successor until N's required deployment and production
verification have passed.

Use CI time to run an independent review or prepare the staged successor;
avoid repeating checks that already passed unless a subsequent change affects
them. This is a one-item look-ahead, not permission to run multiple PRs or
merge multiple changes concurrently.

## The cycle

### 1. Pick and prepare

At the beginning of this iteration, re-read `inbox.md` from the local
worktree before selecting or continuing work. On a new feature pickup, do
this before deciding which feature or plan to take next.

Select work in this order:

1. Continue the existing roadmap item or feature in `in-progress/`.
2. Otherwise, pick the next unfinished roadmap item. Once the main roadmap is
   complete, move the lowest-numbered plan from `docs/features/draft/` to
   `in-progress/` in the feature's first PR.
3. Once there is no unfinished roadmap, in-progress feature, or draft plan,
   triage `inbox.md` for the next actionable item. Create or update the
   repository's normal feature-plan record for it, then take it through this
   same PR loop.

Only conclude that no work is available after re-reading `inbox.md` from disk
at that moment, and confirming no remaining entry can be safely and
autonomously advanced. Step 7 requires the same re-read again after the final
merge. Re-read the selected plan and relevant existing code before editing.

Before starting or delegating work, inspect the worktree, current branch,
existing PRs, and base-branch freshness. Preserve unrelated local changes;
do not overwrite, commit, or incorporate them unless they are part of the
roadmap item.

Start from an up-to-date base branch unless the user asked for a different
base. Branch names should follow the repo's convention; when none exists, use
`pr-N-short-slug` where `N` is the next pull request number if known.

If resuming after an interruption, inspect the existing branch, PR, CI,
deployment, and roadmap state before creating new work. Continue the existing
cycle when possible; do not duplicate branches, PRs, checks, or deployments.

### 2. Implement and verify locally

Build exactly what the roadmap item specifies, logging deliberate deviations.
During iteration, run the narrowest relevant checks for the files and behavior
changed, plus any cheap repository-provided fast gate. Do not routinely run the
full repo-local CI-equivalent suite: required CI is the authoritative full gate
before merge. When CI fails, reproduce and run the failing or affected check
locally before pushing the fix. Run the full suite locally only when CI is
unavailable, a failure is difficult to diagnose, or the user requests it. For
UI changes, inspect the rendered result at desktop and mobile widths, not just
automated tests.

### 2a. Local code review — always, before pushing

**Every change gets a local code-review round before it leaves the machine.**
Local review is the primary gate; cloud review is a second opinion that costs
the user money, may be switched off, and only arrives once the diff is public.

Use local review tooling where it exists — a `/code-review` skill, a review
recipe in the justfile/Makefile — otherwise read the full diff yourself:
correctness, security, error handling, test coverage, config drift, dead code,
and whether the change follows existing local patterns.

Fix what it finds and re-run the affected checks *before* pushing; note any
finding you deliberately leave unfixed in the PR body. Only then open the PR.

### 3. Keep CI green

Ensure the PR title and body identify the roadmap or feature item implemented.
Watch CI; on failure, read the failing logs, fix the actual issue, push, and
re-watch until checks pass or the failure is outside repo control. While
waiting, keep the delivery pipeline full as described above. See "Waiting on
GitHub without stalling" for the exact commands and wait budgets.

### 4. Re-review before merge

Repeat the 2a pass over whatever changed since — CI fixes, review findings,
rebases — so no commit reaches `main` unreviewed. An unmoved head needs only a
quick confirmation. Fix confirmed findings and re-run the relevant checks.

### 4a. Review-bot and reviewer closure gate

Cloud review is **supplementary to** step 2a, never a substitute, and it is
billed to the user. Before merging, fetch the PR's current issue comments,
review comments, and review-thread state. Do this even when CI is green and
the local review found nothing.

For every actionable finding: inspect the *current* code, not the comment's
original diff location; fix it or add a focused regression test; run the
required checks and push. Reply with the fix and commit, and resolve the
thread only once the fix is verified. Re-check comments after that push — a
finding posted against the new head is still a required result.

Do not merge while actionable findings remain, even on an approved PR. If one
does not apply, say why in a reply, with evidence, before merging.

**Do not trigger extra review rounds by default.** Requesting one
(`@codex review` or equivalent) after every pushed fix multiplies the cost
fast. Ask only when the user wants it, or when a fix is substantial enough to
be worth the spend — and say so.

This gate requires you to *look*, not to be reviewed. Having checked reviews,
comments and reactions, a PR with none of them passes it: record "no automated
review was produced" and merge on the local review.

### 5. Merge and deploy

Merge according to repo policy. If the repo deploys automatically from `main`,
watch the deployment for the merged commit. If deploy is manual or not
applicable, follow the repo-local release instructions or state that no deploy
step exists.

### 6. Verify the result

Verify the merged/deployed behavior through the narrowest reliable check:
HTTP health checks, CLI checks, Playwright screenshots, smoke tests, or direct
inspection as appropriate for the repo. If production verification exposes a
bug, fix forward with a small follow-up PR through the same cycle. For
services deployed to u59.local, the `u59-production` skill documents the
SSH/health-check/deploy-watch conventions to use.

### 7. Close the loop

Update the roadmap or feature plan: tick completed PR items, move a completed
feature from `in-progress/` to `done/`, and record deviations. Then start the
next cycle only after the current PR is merged and verified.

**Re-read `inbox.md` from disk before concluding the loop is finished.** The
user edits it *while the loop runs*, so an entry added an hour ago is invisible
to any copy read at pickup — including an uncommitted one, which is how work is
handed to a running loop. Before reporting that nothing remains: read the file
again from disk, treat anything new or changed as work and take it through the
cycle, and when it really is empty, say that you re-read it at the end.

## Waiting on GitHub without stalling

The `github` skill owns the mechanics — the `gh` commands for checks, the query
for "has the bot reviewed this head and is anything unresolved", the reactions
endpoint, and the bounded-poll template. Use it; do not re-derive them here.

Loop-level policy:

- **CI is a fast wait (~3 min)** and is the authoritative full gate before
  merge. Blocking on it once is fine.
- **Never block on a review bot (8–15 min when it runs at all).** Spend the
  time on the staged successor or plan updates, then one cheap status query.
- **Check reactions, not just comments.** A clean review can leave only a 👍,
  which is otherwise indistinguishable from no review at all.
- **Grace window, not an open wait.** No reaction and no result ~10 minutes
  after opening the PR means none is coming: record "no automated review was
  produced" and merge on the step 2a/4 local review. Zero results never means
  "keep waiting indefinitely" — an unreviewed PR is not a blocked PR.
- **The bot may be disabled.** If reviews stop arriving across several PRs, say
  so once and stop requesting them.

## Lightweight items: the fast path

Not every item deserves the full cycle. Docs-only changes, renames, config
tweaks, and other trivial items with no runtime behavior change may skip the
heavyweight parts: implement, run only the checks relevant to the change
(e.g. lint/format, link checks), open the PR, let CI validate, merge —
skipping the deep self-review, deploy-watch, and production verification
steps when nothing deployable changed. When triaging a roadmap or
`docs/features/` backlog, batch-identify these lightweight items up front and
knock them out first or out-of-band, reserving the full expensive cycle for
real features. If in doubt whether an item is truly lightweight (touches CI
config, Dockerfiles, dependencies, or anything that ships), treat it as a
full-cycle item.

## When to involve the human

Ask for help only when hard-blocked: credentials or access are missing,
account actions require the user's identity, an operation is destructive or
out of scope, or the plans leave a real product decision unresolved. State
precisely what is needed and keep working on anything that remains unblocked.
