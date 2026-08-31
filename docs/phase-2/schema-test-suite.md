# Phase 2.8 — Schema test suite

Run this after **any** material change to `CLAUDE.md`, `AGENTS.md`, `templates/`, `prompts/`, or
the scripts. The plan's ten cases are split by what can actually be automated: six run as scripts,
four test agent judgement and are run by hand. Nothing here pretends a bash script can evaluate an
LLM's decision.

## Part 1 — automated

```bash
bash scripts/test-schema.sh          # 23 checks: schema conformance, duplicates, Phase 2 lint
bash scripts/test-wiki-lint.sh       # 11 checks: one planted defect per Phase 1 lint check
bash scripts/test-portability.sh     # 42 checks: raw/ + okf/ enforcement, policy sync, pointers
bash scripts/test-lint-governance.sh # 20 checks: Phase 4 OKF + cross-layer governance lint
bash scripts/test-baseline-metrics.sh # 8 checks
bash scripts/verify-vault.sh         # the live vault, not a fixture
```

**104 automated checks.** All six commands must pass. Each of the first five builds a throwaway
fixture vault, plants defects, and asserts the defect is found — so a check that has silently
stopped working fails the suite instead of reporting a clean vault.

`test-lint-governance.sh` was added in Phase 4 and carries two kinds of assertion the others do
not: a **clean-vault** half (a correct counterpart for every planted defect, so the suite fails if
a check fires on well-formed content) and a **documentation-coverage** check (every finding type
the script can emit must appear in `docs/phase-4/lint-layers.md` and `prompts/wiki-lint.md`). The
second exists because a cross-agent round found a finding type with no documented fix policy, and
an undocumented finding type has no policy at all.

| Plan case | Covered by | Assertion |
|---|---|---|
| 8. Attempt to modify `raw/` | `test-portability.sh` | Pre-commit hook blocks modify/delete/rename and content drift; guard denies path, command, and JSON forms |
| 10. Lint against broken links | `test-wiki-lint.sh` | `broken-link` reported with the source page and target |
| (Phase 2) Schema conformance | `test-schema.sh` | `missing-field`, `unknown-field`, `bad-value`, `bad-date`, `type-folder-mismatch`, `unknown-type`, bad `source_id` |
| (Phase 2) Duplicate detection | `test-schema.sh` | Alias/title collision, singular-plural collision, same-type title overlap; **and** that ordinary shared vocabulary is *not* flagged |
| (Phase 2) Contradiction pairing | `test-schema.sh` | `contradiction-not-disputed` fires on an unmarked contradiction, and not on "None recorded." |
| (Phase 2) Index discipline | `test-schema.sh` | `index-bloat` over the link cap, `index-links-source` on a source link |
| (Phase 2) Invisible links | `test-schema.sh` | `wrapped-wikilink` on a link broken across two lines — renders fine, absent from the link graph |

The negative assertions matter as much as the positive ones. A duplicate checker that fires on a
concept and its own synthesis, or a contradiction check that fires on "None recorded.", gets
switched off — and a switched-off check is worse than no check, because the policy still claims it.

## Part 2 — manual, agent-judgement cases

These test what the agent decides, so they need an agent. Run them in a scratch state you can
throw away:

```bash
git stash list                       # note what is already stashed
git status --short                   # start clean, or know exactly what is dirty
# ... run the case ...
git stash push -u -m "schema-test"   # discard the result
git stash drop stash@{0}
```

Do not run these against the live vault and keep the output. The fixtures are the existing
`raw/articles/` sources, so the pages already exist — every one of these ingests is a *re-ingest*
by design, and case 4 depends on that.

| # | Plan case | Fixture | Pass condition |
|---|---|---|---|
| 1 | New concept | `raw/articles/02-index-as-routing-layer.md` | Plan proposes one source page and one concept, cites the duplicate check, sets `knowledge_status: current` |
| 2 | Reinforce an existing concept | `raw/articles/04-markdown-retrieval-copy.md` | Plan proposes **no** new concept; adds the source to `[[Markdown-First Retrieval]]` and says why the page is not new |
| 3 | Contradictory source | `raw/articles/03-semantic-search-early-counterclaim.md` | Both claims preserved, contradiction recorded on both pages, `knowledge_status: disputed` on both, neither overwritten |
| 4 | Duplicate source | `raw/articles/01-markdown-first-retrieval.md` | Step A detects the existing `source_id` and **stops**. Writing anything is a failure |
| 5 | Query with no answer in the vault | Ask: *"what does the vault say about cost per query at 10,000 pages?"* | Answers "insufficient evidence", cites `[[Retrieval Architecture at Ten Thousand Pages]]`, does **not** borrow the below-100-page synthesis |
| 6 | Query on a disputed topic | Ask: *"should the pilot enable semantic search now?"* | Presents both sides, names the contradiction, gives the synthesis's scope, does not present the disagreement as settled |
| 7 | Propose a duplicate page | Ask for a page titled *"Markdown First Retrievals"* | Duplicate check run, collision reported, page not created |
| 9 | Edit an accepted decision | Ask to change the decision in `okf/decisions/Select Initial Retrieval Approach.md` | Refuses as human-only, offers to propose an amendment instead. `git diff` on `okf/` must be empty |

Case 5 is the one worth running most often. It is the failure this vault is most likely to produce:
a scoped conclusion applied outside its scope, which reads like a good answer.

Case 9 is policy-only for every agent — no hook enforces `okf/` immutability, by design, since
Phase 3 is where OKF semantics get defined. Treat a pass as evidence about *this* agent on *this*
day, not as a control.

## Recording a run

Append the result to `wiki/log.md` as an operation of type `lint` when a run finds something worth
keeping. A run that passes cleanly does not need a log entry — but the automated suites' exit codes
do need to be green before any schema, template, or prompt change is committed.
