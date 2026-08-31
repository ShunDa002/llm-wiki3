# Lint layers, fix policy, and review cadence (Phase 4)

Date: 2026-08-31. Automation level: **2** — the agent proposes plans and executes approved ones.
Nothing in this document turns on auto-repair; §4.2 below is an eligibility register, not a
switch that has been flipped.

Plan reference: [Phase 4 §4.1–4.4](../../LLM-Wiki-and-OKF-Implementation-Plan.md).

## 4.1 The four layers, and which script owns each

The plan divides lint into four layers by *what kind of judgement a finding needs*. That division
matters mechanically here, because the layers have different consequences: two of them gate write
work and two of them ask a human a question.

| Layer | Owned by | In `verify-vault.sh` | Consequence |
|---|---|---|---|
| Structural | `scripts/wiki-lint.sh`, `scripts/check-schema.sh` | sections 3 and 6 | **Hard fail.** A broken link or an invented schema field is wrong regardless of context. |
| Knowledge | `wiki-lint.sh` (contradiction pairing, single-source synthesis, claim blocks), `find-duplicates.sh`, `lint-governance.sh` (review staleness) | 3, 7, 9 | Mixed: mechanical halves hard-fail, semantic halves are advisory. |
| OKF | `scripts/lint-governance.sh` | section 9 | **Advisory.** |
| Cross-layer | `scripts/lint-governance.sh` | section 9 | **Advisory.** |

Why two scripts instead of one: `wiki-lint.sh` is a gate — exit 1 blocks write work. Every OKF and
cross-layer finding is a review prompt about meaning ("this accepted decision rests on knowledge
that changed after it was accepted"), and a review prompt that blocks work teaches its operator to
switch the whole verifier off. That is the same reasoning that keeps the duplicate check advisory,
and it is why the split is by consequence rather than by topic.

### Structural layer — what a script can decide alone

Broken wikilinks, missing required metadata, invalid page type, wrong folder, missing title,
invalid dates, missing log entries, inconsistent aliases. All covered; see
[prompts/wiki-lint.md](../../prompts/wiki-lint.md) for the finding table.

Two structural findings from the plan's list are **not** implemented and should not be:

- *Missing title* — `check-schema.sh` already rejects a page with no `title`, so a second check
  would only add a second place to fix.
- *Inconsistent aliases* — `find-duplicates.sh` matches on aliases already. An alias that is
  "inconsistent" but not colliding is not yet a defect anybody can name.

### Knowledge layer — what needs a human, with the mechanical half automated

| Plan finding | Status |
|---|---|
| Unsupported claims | Semantic. `wiki-lint.sh` catches the structural proxy (`no-sources`, `single-source-synthesis`, `claim-block-incomplete`); "the source does not actually support this" is a read, not a grep. |
| Contradictions | `contradiction-not-disputed` (Phase 2) |
| Superseded evidence | `superseded-page-cited` (new) |
| Duplicate concepts | `find-duplicates.sh` (Phase 2), never auto-merged |
| Overly broad claims | Semantic. The `## Claim` block's `Scope` field exists so a reviewer can see the boundary; nothing can check that prose against reality. |
| Missing concept pages | Semantic, and deliberately not guessed at — see the note on `wiki/questions/` in [phase-2/page-taxonomy.md](../phase-2/page-taxonomy.md). |
| Single-source syntheses | `single-source-synthesis` (Phase 1) |
| Unresolved open questions | `question-stale` (new) |

Plus two staleness checks the plan implies through its cadences rather than its finding list:
`claim-review-stale` and `claim-review-undated`. A claim block asserts rigour; once its
*Last reviewed* date is older than the review cadence, it asserts rigour it no longer has.

### OKF layer — `lint-governance.sh`

| Plan finding | Check | Note |
|---|---|---|
| Goal without review date | `okf-no-review-date` | Written against `okf/*/` generically, so a `goals/` folder added later is covered without an edit. Currently applies to projects and decisions. |
| Project without linked goal | `project-no-knowledge` | `goals/` does not exist yet (see [okf-bridge.md §3.1](../phase-3/okf-bridge.md)). The equivalent in this vault's shape is `informed_by`: what ties execution to compiled knowledge. |
| Decision without knowledge basis | `no-knowledge-basis` | Already in `wiki-lint.sh`; not duplicated here. |
| Experiment without conclusion | `no-conclusion` / `empty-conclusion` | Already in `wiki-lint.sh`. |
| Debrief without action items | *not implemented* | No `debriefs/` folder. A check against a folder that does not exist can never fire, and writing one now means guessing its schema. |
| Action item without destination | *not implemented* | Same. |
| Practice without supporting evidence | *not implemented* | Same — `okf/practices/` is deliberately closed. |
| Active project based on disputed knowledge | `project-on-disputed-knowledge` | Follows `informed_by`, then one hop through `based_on`, because a synthesis can legitimately be `current` while both concepts under it stay `disputed`. That is this vault's actual shape, and hiding it behind a one-level check would defeat the finding. |

Two checks not in the plan's list, added because Phase 3 left the gap and named it:

- `experiment-no-decision` — an experiment testing nothing has nowhere to send its result.
- `link-not-reciprocal` — `validated_by` and `tests_decision` must agree in both directions. Phase
  3 documented the relationship and enforced neither end, and of the first two decision/experiment
  pairs this vault ever held, **one was already asymmetric** (found by accident, through a
  copy-paste in a cross-agent test fixture). A one-way link means `/bridge-impact` walks the graph
  in one direction and silently misses affected work.
- `okf-review-overdue` — a review date that has passed is the cadence failing in public.

### Cross-layer — `lint-governance.sh`

| Plan finding | Check |
|---|---|
| Wiki update affects an accepted decision | `knowledge-changed-since-decision` — a `knowledge_basis` page whose `updated` is later than the decision's `decision_date`. This is `/bridge-impact` run backwards: the workflow starts from a page the operator already knows changed, which is no help for a change nobody remembered to follow up. |
| A decision links to a superseded synthesis | `decision-cites-superseded`, plus `decision-cites-disputed` for `disputed`/`uncertain`, plus `decision-basis-missing` when the cited page does not exist at all |
| A project cites raw sources directly even though a synthesis exists | `okf-cites-evidence-only` |
| A synthesis has high reuse but no index entry | *not implemented* — `index-omission` already flags **every** synthesis missing from the index, which is stricter than the reuse-weighted version and needs no threshold nobody has calibrated. |
| Debriefs repeatedly show the same failure pattern | *not implemented* — no `debriefs/`. |
| A practice conflicts with newer evidence | *not implemented* — no `practices/`. |

`okf-cites-evidence-only` requires **both** halves of the plan's sentence: the page reaches into
`raw/` or `wiki/sources/` **and** cites no compiled page at all. The first draft dropped the
"even though a synthesis exists" qualifier and immediately fired on this vault's experiment page,
which cites the source record *of itself* — provenance, not a bypass. The negative case is now a
test assertion, for the same reason Phase 2's two tuned heuristics are.

## 4.2 Fix policy by finding type

The plan's table, resolved against what exists. **No auto-fix is enabled.** Column 3 is the
condition under which enabling it would become defensible, not a promise to enable it.

| Finding | Policy now | Auto-fix eligible when |
|---|---|---|
| `wrapped-wikilink`, formatting | Propose | Never mechanically ambiguous — eligible after one observation period. The cheapest real candidate. |
| `missing-field` for a safe field (`updated`, `created`) | Propose or auto-fill on approval | Eligible; the value is derivable from git history, not invented. |
| `broken-link` with exactly one matching title | Propose | Eligible after an observation period. Two candidate targets is never auto-fixable. |
| `broken-link`, ambiguous or no candidate | Propose only | Never |
| `index-omission` | Propose | Never — what belongs in the index is a routing judgement (plan §2.7). |
| `duplicate-filename`, `near-duplicate`, `key-collision`, `similar-title` | Propose | **Never auto-merge.** |
| `contradiction-not-disputed` | Propose the field change | Never — setting `knowledge_status` is a claim about knowledge. |
| `decision-cites-superseded`, `decision-cites-disputed`, `knowledge-changed-since-decision` | Notify and propose review | **Never.** Lint does not reopen an accepted decision, at any automation level (plan §7.3). |
| `decision-basis-missing` | Propose | Never — a decision citing a page that does not exist is either a typo or a missing page, and which one it is decides the fix. |
| `project-on-disputed-knowledge` | Notify | Never |
| `project-no-knowledge`, `experiment-no-decision` | Propose the missing link | Never — which knowledge informs a project, and which decision an experiment tests, are both judgements about intent. |
| `okf-cites-evidence-only` | Propose the compiled page to cite instead | Never — the right replacement may not exist yet, in which case the fix is an ingest, not an edit. |
| `superseded-page-cited` | Notify the citing page's owner | Never — the citation may still be correct as history. |
| `claim-review-undated` | Propose adding a `Last reviewed` line | Never auto-*dated*: only a human can say a review happened. Proposing the empty line is the whole eligible action. |
| `okf-no-review-date`, `okf-review-overdue` | Notify the owner | Never — a date is a commitment. |
| `link-not-reciprocal` | Propose the missing back-link | Eligible for the *append* direction only, and only when the target is not an accepted decision or a completed experiment — which is most of the time exactly what it is, so treat as never in practice. |
| `claim-review-stale`, `question-stale` | Notify | Never — re-dating a review that did not happen is a lie the schema would then carry. |
| Page deletion | Prohibited | Never |
| Page rename | Owner only | Never |

Enforcement of the last two rows is not documentary: `.githooks/pre-commit` +
`scripts/check-okf-guard.sh` block a committed change to an accepted decision, a completed
experiment, or a project's `status`/`owner`/dates, under any agent.

## 4.3 Review cadences

Run under any agent; every command is read-only.

### After each ingest

```bash
bash scripts/verify-vault.sh          # sections 1–8 gate; 9 is advisory
git status --short                    # the files that changed must match the approved plan
```

### Weekly — structural

```bash
bash scripts/wiki-lint.sh
bash scripts/check-schema.sh
git status --short raw/               # unprocessed sources waiting in the inbox
```

Review: new findings since last week, synthesis candidates, any operation that failed or was
interrupted (`wiki/log.md` tail).

### Monthly — knowledge, OKF, and cross-layer

```bash
bash scripts/verify-vault.sh
bash scripts/lint-governance.sh       # the full advisory layer, not just verify-vault's summary
bash scripts/find-duplicates.sh
```

Review: every governance finding, disputed and stale pages, orphan clusters, and accepted
decisions whose knowledge has changed. Record the run in
[maintenance-log.md](maintenance-log.md) — the workload number is a Phase 4 exit criterion, and it
cannot be recovered retrospectively.

### Quarterly — schema and controls

```bash
bash scripts/test-portability.sh scripts/test-schema.sh   # (run each; both must pass)
bash scripts/check-policy-sync.sh
bash scripts/lock-raw.sh && bash scripts/verify-vault.sh  # recovery + lock drill
```

Review: schema complexity (is any approved field unused?), retrieval performance, privacy
classifications, the Git recovery checklist, and whether the automation level should move.

## 4.4 Graph view as quality evidence

Obsidian's graph is the one check here with no script, because what it shows is shape. What to look
for, and what the scripted equivalent is when there is one:

| Look for | Scripted equivalent |
|---|---|
| Orphan pages | `orphan` in `wiki-lint.sh` |
| `raw/` sources with no Wiki representation | none — `git status --short raw/` is the proxy; 12 files currently uningested |
| Wiki concepts with no source relationships | `no-sources` |
| Dense research clusters with no OKF application | none — this is exactly what the graph is for |
| Project clusters disconnected from general knowledge | `project-no-knowledge`, partially |
| Overloaded hub pages | `index-bloat`, for the index only |
| Accepted decisions with weak evidence paths | `/wiki-trace`, run per decision |

The graph is evidence, not a finding. Anything it surfaces gets recorded as a lint finding or an
open question before it counts as known.
