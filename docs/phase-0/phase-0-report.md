# Phase 0 completion report

Date: 2026-08-24
Baseline commit: `6dd65a3`, tag `phase-0-baseline`
Pilot owner: shonda_tay@wiwynn.com

## Deliverables

| Deliverable | Where | State |
|---|---|---|
| Pilot scope statement | [pilot-scope.md](pilot-scope.md) | Done |
| Named pilot owner | [pilot-scope.md](pilot-scope.md) | Done |
| Risk matrix | [risk-matrix.md](risk-matrix.md) | Done |
| Privacy policy | [privacy-policy.md](privacy-policy.md) | Done |
| Git recovery checklist | [git-recovery-checklist.md](git-recovery-checklist.md) | Done, drilled |
| Baseline metrics | [baseline-metrics.md](baseline-metrics.md) | Done — automated counts re-runnable; the six manual metrics recorded 2026-08-31, labelled as estimates where they are estimates |
| Initial folder structure | repository root | Done |

## Exit criteria

| Criterion | Evidence | Verdict |
|---|---|---|
| A deleted test file can be restored in under five minutes | Drill test 5: `rm` then `git restore`, file back, tree clean. Whole six-test drill ran in under 1 second | Pass |
| The agent cannot write to `raw/` | Live-tested both paths. `echo probe > raw/hook-probe.txt` denied by the PreToolUse hook; `Write raw/hook-probe.md` denied by the path rule. `raw/` still contains only `.gitkeep` | Pass |
| The pilot owner understands the approval model | Model written in three tiers in `AGENTS.md` and [risk-matrix.md](risk-matrix.md), with per-operation enforcement named. **Signed off by shonda_tay@wiwynn.com, 2026-08-31**, after reviewing the low/medium/high tiers and the prohibited list; no modifications requested | Pass |
| High-risk actions are explicitly prohibited | Enumerated in `CLAUDE.md` and the risk matrix; backed by `deny`/`ask` rules for `rm -rf`, `git push`, `git commit`, `mv`, `templates/**`, `okf/**` | Pass |
| The test vault contains no secrets or restricted data | Vault holds only process documents and empty content folders; `raw/`, `wiki/`, `okf/`, `templates/` are empty. Pilot restricted to `public` and `internal` classifications | Pass |

## What was tested, not just written

- `raw/` guard: 7 pipe-test cases (4 deny, 3 allow) plus 2 live tool calls, both denied.
- Recovery: all 6 procedures from task 0.2, output recorded in the checklist.
- Metrics script: verified against a fixture vault with planted defects — one duplicate
  filename, two dangling wikilinks, a note without sources, an unconcluded experiment — all
  detected. `scripts/test-baseline-metrics.sh` keeps that honest.

One real bug surfaced during that verification: the first version of the link scan piped
filenames through `xargs`, which split on spaces and silently reported zero broken links and
zero linked notes. It was found only because the fixture had known-bad links to compare against.
A metrics script that reports "0 problems" because it is looking at nothing is worse than no
script, which is why the self-check is committed alongside it.

## Open items before Phase 1

1. ~~**Owner sign-off on the approval model.**~~ **Closed 2026-08-31.** Accepted by
   shonda_tay@wiwynn.com after reviewing the three tiers and the prohibited-operations list. Note
   for future readers: the policy text now lives in `AGENTS.md`, not `CLAUDE.md`, which was
   reduced to an `@AGENTS.md` import when the two copies were collapsed — read `AGENTS.md`.
   **All five Phase 0 exit criteria are now met.**
2. ~~**Manual baseline timings.**~~ **Closed 2026-08-31,** recorded in
   [baseline-metrics.md](baseline-metrics.md) — captured retrospectively and labelled as
   estimates where they are estimates, which is the honest form. The automated counts are
   re-runnable with `bash scripts/baseline-metrics.sh` for a matched before/after pair.
3. **Add 10 to 20 pilot sources to `raw/`.** Human action by design — the agent is blocked from
   writing there. **Partially done:** 19 files are tracked under `raw/` plus `.gitkeep` — 7 original
   pilot articles, 1 boundary-probe artifact, 10 notes, and 1 file in a new `raw/inbox/`. The count
   satisfies the "10 to 20" range on paper, but **only the 7 original articles are ingested**, and
   the 12 others are a different domain from the pilot's declared scope. The bottleneck is therefore
   no longer supply, it is your scope decision — see
   [../phase-3/status.md](../phase-3/status.md#open-items-for-the-pilot-owner).
4. **Confirm the enforcement scope.** Permission rules and the hook apply to agents started in
   this project directory. A session started elsewhere, or with `bypassPermissions`, does not
   inherit the `ask` rules; the hook and `deny` rules are the layer that still holds.

Phase 1 should not start until items 1 to 3 are closed.

## Deliberate omissions

Phase 0 establishes controls only, so the following were left out on purpose, not overlooked:

- No `wiki/` subfolders (`concepts/`, `sources/`, `syntheses/`) — Phase 1.1 defines those.
- No template files in `templates/` — templates are schema, and schema changes are high-risk;
  Phase 1.3 defines the minimum set.
- No `/wiki-ingest`, `/wiki-query`, or `/wiki-lint` commands — Phase 1.
- No `wiki/index.md` or `wiki/log.md` — they get their first entries during Phase 1 ingestion.
