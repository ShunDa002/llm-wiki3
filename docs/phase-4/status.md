# Phase 4 status — lint, governance, and maintenance

Date: 2026-08-31. Automation level: **2**, deliberately not the 3 the plan permits — see below.

Objective (plan §4): make deterioration detectable and maintenance repeatable. Phase 4's premise is
that the vault already has three of the four lint layers and does not know it: `wiki-lint.sh`,
`check-schema.sh`, and `find-duplicates.sh` cover structural and part of knowledge lint, and
`check-okf-guard.sh` protects OKF semantics without reporting on them. What was missing was the OKF
and cross-layer *reporting* layers, a fix policy per finding type, and any record of what
maintenance costs.

Full detail: [lint-layers.md](lint-layers.md), [maintenance-log.md](maintenance-log.md).

## What was built

| Plan task | Delivered |
|---|---|
| 4.1 Divide lint into four layers | [lint-layers.md §4.1](lint-layers.md#41-the-four-layers-and-which-script-owns-each) — each layer mapped to the script that owns it, with every plan finding marked implemented, already-covered, or deliberately not implemented and why. `scripts/lint-governance.sh` (new) implements the OKF and cross-layer layers plus two knowledge-layer staleness checks. |
| 4.2 Define fix policy | [lint-layers.md §4.2](lint-layers.md#42-fix-policy-by-finding-type) — the plan's table resolved against real finding types, with an auto-fix *eligibility* column covering all 15 governance types plus the structural classes (21 rows). Nothing is enabled. |
| 4.3 Introduce review cadences | [lint-layers.md §4.3](lint-layers.md#43-review-cadences) — after-ingest, weekly, monthly, quarterly, each as runnable read-only commands. |
| 4.4 Use Graph View as quality evidence | [lint-layers.md §4.4](lint-layers.md#44-graph-view-as-quality-evidence) — what to look for, and the scripted equivalent where one exists, so the graph is used for the three things no script can see. |

Wiring: `verify-vault.sh` gained section 9 (governance lint, **advisory**), `prompts/wiki-lint.md`
gained the governance step and finding table, `.claude/commands/wiki-lint.md`'s `allowed-tools`
gained the new script, and `AGENTS.md` moved to Phase 4 with a read-before-acting pointer at
`lint-layers.md`.

## Why the new checks live in a second script

`wiki-lint.sh` is a gate: `verify-vault.sh` section 3 hard-fails on its findings and blocks write
work. Every OKF and cross-layer finding is a review prompt about *meaning* — "this accepted decision
rests on knowledge that changed after it was accepted" is a question, not a broken invariant. Making
those block write work would either stop legitimate work or force the operator to switch the
verifier off; folding them into the gate and demoting the gate would lose the hard failure on a
broken link. So the split is by consequence, matching the reasoning that already keeps
`find-duplicates.sh` advisory.

## Why automation level stays at 2

The plan puts Phase 4 at "2 to 3", where 3 means the agent executes low-risk operations
autonomously. No auto-fix is enabled here, for one reason: the fix policy table's eligible entries
are all conditioned on an *observation period* that has not happened yet. `wrapped-wikilink` repair
and safe-metadata fill are the two genuine candidates; both are worth enabling after the monthly
cadence has run a few times and the maintenance log shows their false-positive rate. Documenting
eligibility is a Phase 4 exit criterion; flipping the switch is not.

## Verified, not asserted

- `scripts/test-lint-governance.sh` — **20 checks**: one planted defect per governance check (15),
  the negative case that killed the one real false positive, the exit code, a clean vault producing
  no findings at all, a hash comparison proving the script writes nothing, and — added after the
  cross-agent round below — a documentation-coverage check asserting every finding type the script
  can emit appears in both `lint-layers.md` and `prompts/wiki-lint.md`.
- The clean-vault half is the precision evidence, not a formality: it contains a correct counterpart
  for every planted defect, including the decision/experiment pair with reciprocal links and the
  experiment that cites both its own source record and a compiled page.
- All five suites pass: portability 42, schema 23, lint-governance 20, wiki-lint 11,
  baseline-metrics 8 — **104 automated checks**.
- `verify-vault.sh` all clear; `check-policy-sync.sh` and `check-command-pointers.sh` clean after
  the phase bump and the new tool permission.
- One live false positive was found and fixed *before* shipping, by running the script against the
  real vault rather than only the fixtures: `okf-cites-evidence-only` fired on
  `okf/experiments/Native Retrieval Benchmark.md`, which links the source page recording the
  experiment itself. The plan's own wording ("even though a synthesis exists") was the missing
  condition. This is the third time in this vault a check has needed tuning rather than shipping —
  the same shape as Phase 2's similar-title ratio and its "None recorded." exemption.

## Cross-agent verification (Antigravity / Gemini CLI, 2026-08-31)

Seventh cross-agent round, same discipline as the six before it: fixtures inside the prompt, result
re-checked against real repo state rather than taken on the report's word. Prompt and report in
`error-tracking/`.

**Report claimed PASS; independent verification confirms it, with two corrections.** The strongest
evidence is reproducibility of numbers a paraphrased run cannot invent: the four raw-file sha256
hashes in its traceability walk were recomputed here and match byte-for-byte; its finding **counts**
match a rebuild of the same six fixtures done independently in a scratch copy — 18 findings with
fixtures present, 15 at `VAULT_TODAY=2026-01-01`, 20 at `VAULT_STALE_DAYS=0`; and all 15 governance
checks fired on the same files. Cleanup was exact: no `ZZZ P4` file remains, `okf/` is clean, and —
unlike an earlier round — `wiki/log.md` kept its pre-existing uncommitted entry (21 insertions, zero
`ZZZ P4` lines), because this prompt forbade `git restore` outright.

**One real defect found, in this phase's own documentation.** Task J compared each of the 15
governance finding names across the script, `prompts/wiki-lint.md`, and this phase's
`lint-layers.md`, and reported `decision-basis-missing` missing from the third. Confirmed — and
checking further showed the gap was wider than the report found: **§4.2 had no fix-policy row for 7
of the 15 governance types** (`decision-basis-missing`, `decision-cites-disputed`,
`project-no-knowledge`, `experiment-no-decision`, `okf-cites-evidence-only`,
`superseded-page-cited`, `claim-review-undated`). Since "auto-fix eligibility is documented by
finding type" is an exit criterion, that was a real hole in the deliverable, not a cosmetic one.
Both are now fixed: §4.1's cross-layer row names `decision-basis-missing`, and §4.2 covers all 15.
The report deserves credit for the thread; the audit it prompted found the rest.

**One error in the report.** Task O claims two uningested files under `raw/`
(`probe-add-only.md`, `inbox/python-list-test.md`). The real number is **12** — its shell equivalent
missed the ten notes under `raw/notes/Python/`, `raw/notes/Agentic-AI/`, and
`raw/notes/sbx-Sandbox/`, which sit one directory deeper than a `raw/*/*.md` glob reaches. Same
class of bug as the Phase 0 `xargs` split and the wrapped-wikilink blind spot: a scan that looks
exhaustive and silently is not. The vault's own count (12) is unaffected and correct.

**Two prompt defects, fixed for the next round.** The explanatory note about wikilink brackets sat
*inside* Fixture 3's fenced block, so the fixture body carried a literal `[[...]]` and produced one
extra `broken-link` finding — correctly reported, harmless, now moved outside the fence. And task
F.3 asked for an `index-omission` policy lookup, which these fixtures can never produce because that
check only examines syntheses; the report handled it gracefully by quoting the policy row without
claiming the finding fired.

Not established by this PASS, recorded so it is not over-read: the round ran on Linux with GNU
coreutils, so the BSD `date` branch in `stale_cutoff()` is still unexercised — the same
shell-dialect gap the Phase 3 round left open.

## Traceability drill (exit criterion)

"The system can trace every accepted pilot decision to evidence." There is one accepted decision;
walked mechanically, not by assertion:

```
okf/decisions/Select Initial Retrieval Approach.md   (status: accepted, decision_date 2026-08-24)
  knowledge_basis
    wiki/syntheses/Markdown-First Retrieval vs Early Semantic Search for Small Pilot Vaults.md
      sources
        wiki/sources/Source - Markdown-First Retrieval for Small Knowledge Vaults.md
          raw_file  raw/articles/01-markdown-first-retrieval.md          (45 lines, present, 444)
        wiki/sources/Source - Markdown Retrieval for a Small Wiki.md
          raw_file  raw/articles/04-markdown-retrieval-copy.md           (26 lines, present, 444)
        wiki/sources/Source - Semantic Search Should Be Enabled During the Pilot.md
          raw_file  raw/articles/03-semantic-search-early-counterclaim.md (36 lines, present, 444)
        wiki/sources/Source - Pilot Experiment - Native Retrieval Benchmark.md
          raw_file  raw/articles/05-experiment-result-native-search.md    (44 lines, present, 444)
  validated_by
    okf/experiments/Native Retrieval Benchmark.md  (status: complete, tests_decision points back)
```

Every hop resolves to a file that exists, and the leaves are read-only evidence whose hashes match
their recorded `source_id` (`verify-vault.sh` section 2b). Both sides of the underlying
contradiction are represented in the chain — source 03 argues the opposite of 01 — which is what
makes this a traceable decision rather than a one-sided one.

## Exit criteria

| Criterion | State |
|---|---|
| Structural lint precision is acceptable to reviewers | **Met at this scale, needs the owner to confirm.** This round: 3 findings, 3 true positives, 0 false positives; one false positive found and fixed pre-ship. A second agent reached the same three verdicts independently (see the cross-agent section above). Recorded per run in [maintenance-log.md](maintenance-log.md). |
| Semantic lint does not silently modify content | **Met.** `lint-governance.sh` has no write path, and `test-lint-governance.sh` asserts a byte-identical vault before and after a run. |
| Monthly lint identifies known planted defects | **Met.** 15 planted defects, one per governance check, all detected. |
| The system can trace every accepted pilot decision to evidence | **Met.** One accepted decision, walked above to four raw files. |
| Maintenance workload is measured and remains sustainable | **Half met.** Machine time measured (4.7 s for the full monthly cadence). Human review time is the number that decides sustainability and only the owner can record it — the column is deliberately blank rather than estimated. |
| Auto-fix eligibility is documented by finding type | **Met, after a gap the cross-agent round exposed.** [lint-layers.md §4.2](lint-layers.md#42-fix-policy-by-finding-type) now covers **all 15** governance types plus the structural classes — 21 rows. As first written it silently omitted 7 governance types, which the round-7 documentation audit surfaced. |

## Open items for the pilot owner

1. **Record human review time** for the next monthly run in
   [maintenance-log.md](maintenance-log.md). Without it, "sustainable" is an opinion.
2. **Confirm lint precision is acceptable** — the reviewer-judgement half of the first exit
   criterion, same shape as Phase 0's approval-model sign-off and Phase 2's taxonomy confirmation.
3. **Decide whether to enable the two auto-fix candidates** (`wrapped-wikilink`,
   safe-metadata fill) after two or three recorded monthly runs. Not before: the eligibility
   condition in §4.2 is an observation period, and there has been one run.
4. **Decide what to do about `project-on-disputed-knowledge` recurring.** It is a true positive and
   will fire on every run while the pilot rests on a scoped resolution of a live disagreement. The
   options are to accept a permanent standing finding, or to record the acceptance somewhere the
   check can read — which would be a schema change, and therefore owner-only.
