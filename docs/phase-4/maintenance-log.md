# Maintenance log

One row per lint or review run. This file exists because "maintenance workload is measured and
remains sustainable" is a Phase 4 exit criterion, and workload cannot be reconstructed
retrospectively — an unrecorded run is an unmeasured one.

Record the machine cost (measured, cheap) and the human cost (the number that actually decides
sustainability). Leave the human column blank rather than guessing; a blank is information, an
invented number is not.

| Date | Cadence | Run by | Machine time | Human review | Findings | Actions taken |
|---|---|---|---|---|---|---|
| 2026-08-31 | monthly (first full run) | Claude Code | 4.7 s total | *owner to record* | 3 governance, 0 structural, 0 schema, 0 duplicate | None. All 3 are review prompts; see below. |
| 2026-08-31 | weekly + monthly, inside cross-agent round 7 | Antigravity / Gemini CLI | 2.11 s weekly, 4.01 s monthly | *not recorded — verification run, not a maintenance pass* | same 3 governance findings; 18 with the round's 6 fixtures in place | None on vault content. The round found one documentation defect, fixed the same day — see below. |

## 2026-08-31 — first full four-layer run

Machine time, measured on this vault (7 sources, 4 concepts, 1 synthesis, 1 question, 3 OKF
records, 20 evidence files):

| Script | Time |
|---|---|
| `wiki-lint.sh` | 0.62 s |
| `check-schema.sh` | 0.68 s |
| `lint-governance.sh` | 0.36 s |
| `find-duplicates.sh` | 0.44 s |
| `verify-vault.sh` (wraps all four, plus 6 more sections) | 2.6 s |

The whole monthly cadence is under 5 seconds of machine time at this scale. That number is
recorded now precisely so a later one is comparable: the checks are `O(pages²)` in the link-graph
scan, so this is the figure to watch as source count grows toward the 20-source criterion and
beyond.

Findings, all three from the governance layer, all confirmed true positives on review:

1. `project-on-disputed-knowledge` ×2 — `[[LLM Wiki Pilot]]` is `informed_by` a `current`
   synthesis whose two `based_on` concepts are both `disputed`. **Correct and intended state**, not
   a defect: the synthesis resolves the retrieval-timing contradiction *for vaults below ~100
   pages* and says so, while both concepts stay disputed in general. Action: none. This is the
   finding the one-hop check exists to surface — an operator should know their active project rests
   on a scoped resolution of an open disagreement.
2. `knowledge-changed-since-decision` — `[[Select Initial Retrieval Approach]]` was accepted
   2026-08-24; its knowledge basis was `updated` 2026-08-30. Reviewed: the update was Phase 2's
   metadata migration (`knowledge_status` and `aliases` added), not a change to the conclusion the
   decision rests on. Action: none, and deliberately no re-dating — lint does not touch an accepted
   decision, and the finding recurring is preferable to a field edited to silence it.

Structural, schema, and duplicate layers: clean. `verify-vault.sh`: all clear — 10 printed sections plus the unheaded content-drift subcheck, which
is the count earlier docs record as 10 and this round takes to 11.

**Precision at this run: 3 findings, 3 true positives, 0 false positives** — after one false
positive was found and fixed during development (`okf-cites-evidence-only` fired on an experiment
citing the source record of itself; the "even though a synthesis exists" condition was missing).
That fix is now a test assertion in `scripts/test-lint-governance.sh`.

## 2026-08-31 — cross-agent round 7 (second row above)

A verification pass rather than a maintenance one, logged here because it re-ran both cadences and
produced comparable timings on a different machine: **weekly 2.11 s, monthly 4.01 s**, against 0.62 /
0.68 / 0.36 / 0.44 / 2.6 s per script measured here. Same order of magnitude, which is all the
comparison is for.

It reached the same three verdicts on the three live findings, independently — the second data point
for the "precision is acceptable" exit criterion, though still not the owner's confirmation.

Its one substantive finding was in the documentation, not the vault: a governance finding type
(`decision-basis-missing`) had no row in this phase's §4.1 table, and a follow-up audit found 7 of
the 15 types with no §4.2 fix-policy row at all. Both fixed, and the class is now an automated check
(`test-lint-governance.sh`, 19 → 20 checks) rather than something a reviewer has to notice. Detail in
[status.md](status.md#cross-agent-verification-antigravity--gemini-cli-2026-08-31).
