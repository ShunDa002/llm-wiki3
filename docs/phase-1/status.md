# Phase 1 status: MVP minimum closed loop

Date: 2026-08-24
Automation level: 1 to 2 (agent proposes, executes approved plans)

## Built and tested

| Task | Deliverable | Verified |
|---|---|---|
| 1.1 folder structure | `wiki/{concepts,sources,syntheses}`, `okf/{projects,decisions,experiments}`, `wiki/index.md`, `wiki/log.md` | Present |
| 1.2 operating rules | `CLAUDE.md` at Phase 1, command references, prohibitions | Present |
| 1.3 metadata schema | 6 templates + schema summary in `CLAUDE.md` | Present |
| 1.4 `/wiki-ingest` | `.claude/commands/wiki-ingest.md` — 5-step transaction | Registered |
| 1.5 `/wiki-query` | `.claude/commands/wiki-query.md` — index-first, cited, read-only | Registered |
| 1.6 query file-back | Classification and proposal format inside `/wiki-query` | Registered |
| 1.9 lint | `.claude/commands/wiki-lint.md` + `scripts/wiki-lint.sh` | 10/10 planted defects caught |

`scripts/lib-vault.sh` holds the link-graph and frontmatter helpers shared by
`wiki-lint.sh` and `baseline-metrics.sh`, so the parsing that broke once in Phase 0 exists in one
place. Both self-checks pass after the refactor.

## Blocked: needs sources in raw/

Tasks 1.7 (OKF application), 1.8 (observed result), the MVP acceptance test, and every Phase 1
exit criterion require real sources. The agent cannot supply them — it is barred from writing
`raw/`, which is the control working as designed, not an obstacle to route around.

The `raw/` subfolders could not be created either: `mkdir raw/articles` was denied by
`.claude/hooks/protect-raw.sh`. The guard cannot distinguish an empty scaffold directory from
evidence tampering, and widening it to allow `mkdir` would open the exact hole Phase 0 closed.
Owner action, not a bug to fix.

### Owner steps to unblock

```bash
mkdir -p raw/articles raw/notes raw/assets
# add 5+ sources as .md into raw/articles/ (public or internal only)
git add -A && git commit -m "Add pilot sources"
```

Then, per source: `/wiki-ingest raw/articles/<file>` — review the plan, approve, review the diff,
commit. The plan calls for five individual ingestions before any batch work.

## Exit criteria

| Criterion | State |
|---|---|
| At least five sources ingested individually | Blocked — no sources |
| Zero unauthorized changes to `raw/` | Holding: 3 write attempts denied so far, `raw/` has only `.gitkeep` |
| All factual Wiki pages have source links | Enforced by `/wiki-ingest`; `no-sources` lint check verifies |
| At least one query file-back approved | Blocked |
| At least one Wiki insight influenced an OKF record | Blocked |
| At least one result flowed back into knowledge | Blocked |
| All operations appear in `wiki/log.md` | Mechanism in place; `no-log-entry` check verifies |
| Lint identifies at least the known test defects | **Pass** — `scripts/test-wiki-lint.sh`, 10/10 |
| Rollback successfully tested | Pass in Phase 0; re-test after the first real ingest |

Two criteria pass now. Six need sources. One re-tests after the first ingest.

## Design notes worth keeping

**Read the Wiki before the source.** `/wiki-ingest` orders Step B index-first, source-last. The
reverse order biases toward creating new pages instead of recognising existing ones, which is the
duplicate-fragmentation failure mode Phase 2 exists to clean up.

**Most query answers should be thrown away.** `/wiki-query` defaults to `Ephemeral`. Saving every
answer rebuilds the clipping archive the Wiki replaces.

**Lint recommends, never repairs — including the obvious cases.** An unambiguous broken link is a
Phase 4 auto-fix candidate. Fixing it in Phase 1 means the first time auto-repair goes wrong,
nobody has a baseline for how often it was right.

**A synthesis with one source is a summary.** `single-source-synthesis` is a lint finding for that
reason.

## Not built (deliberately)

- No `/wiki-synthesize`, `/wiki-trace`, `/bridge-*`, `/ops-*` — Phases 2, 3, 6.
- No `wiki/entities/`, `questions/`, `overview.md` — Phase 2.2, on real need.
- No embeddings, vector store, Dataview, scheduler — Phase 5 at the earliest, and only against
  measured retrieval limits.
- No auto-fix in lint — Phase 4.
