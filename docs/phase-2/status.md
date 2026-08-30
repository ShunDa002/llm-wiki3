# Phase 2 status — schema stabilization and quality control

Date: 2026-08-30. Automation level: **2** — the agent proposes plans and executes approved ones.

Phase 2 turns the working Phase 1 loop into a repeatable process. The theme of every change here
is the same: a rule that existed only as an instruction became a rule a script can check, and the
schema grew only where a real Phase 1 failure demanded it. See
[mvp-failure-review.md](mvp-failure-review.md) for the evidence behind each change.

## What was built

| Plan task | Delivered |
|---|---|
| 2.1 Analyze MVP failures | [mvp-failure-review.md](mvp-failure-review.md) — 7 observed failures, 12 patterns explicitly *not* observed and the changes therefore not made |
| 2.2 Expand the taxonomy | `wiki/questions/` and `templates/question.md` only. Five other types deferred with a named trigger each |
| 2.3 Define page semantics | [page-taxonomy.md](page-taxonomy.md) — a 5-question decision rule, per-type table, concept-vs-synthesis worked example |
| 2.4 Claim-level provenance | Optional `## Claim` block (Support / Scope / Confidence / Counter-evidence / Last reviewed), in use on the one high-value claim the vault currently has; `claim-block-incomplete` lint check; `/wiki-trace` |
| 2.5 Aliases and duplicate detection | `aliases` field; `scripts/find-duplicates.sh` implementing all seven checks; `/wiki-find-duplicates`; ingest now runs it before proposing a page |
| 2.6 Contradiction vs update | `knowledge_status: current \| disputed \| superseded \| uncertain` and `review_needed`; `contradiction-not-disputed` lint check pairing the field to the section |
| 2.7 Indexing rules | [page-taxonomy.md#indexing-rules](page-taxonomy.md#indexing-rules); `index-bloat`, `index-links-source`, `index-links-raw` lint checks |
| 2.8 Schema test suite | [schema-test-suite.md](schema-test-suite.md) — 6 automated cases in `scripts/test-schema.sh` (23 checks), 8 agent-judgement cases as a manual checklist with existing fixtures |

New quality-control scripts: `check-schema.sh` (frontmatter conformance, including rejecting
unapproved fields), `find-duplicates.sh`, `test-schema.sh`. Both new checkers are wired into
`verify-vault.sh` — schema as a hard check, duplicates as advisory, because a title collision is a
question for a human, not a broken vault.

## Exit criteria

| Criterion | Status |
|---|---|
| Twenty representative sources processed | **Not met — owner action.** 7 sources ingested. The machinery is ready for 20; the sources have to exist, and the agent cannot write to `raw/` |
| Duplicate page rate below the agreed threshold | **Threshold now set, rate met.** Adopting the plan's §7.6 figure of under 2 percent. Current rate: 0 duplicates across 6 knowledge pages, `find-duplicates.sh` clean |
| All high-value claims have traceable provenance | **Met at current scale.** One high-value claim exists — the below-100-pages retrieval claim — and it now carries a full claim block with scope, counter-evidence, and a review date. `/wiki-trace` exists to re-check it. Re-assess after 20 sources |
| Contradictions are visible and not silently resolved | **Met.** Both sides of the retrieval contradiction are `knowledge_status: disputed`, recorded on both pages with both sources, and lint fails if a recorded contradiction is not marked |
| Templates pass the schema test suite | **Automated half met, now under two agents.** Green under Claude Code and, independently verified, under Antigravity/Gemini CLI — see [Cross-agent verification](#cross-agent-verification-antigravity--gemini-cli) below. **The 8-case manual checklist against the vault's real fixtures is still not run**; see [schema-test-suite.md](schema-test-suite.md) |
| Reviewers consistently understand the page taxonomy | **Not agent-completable.** [page-taxonomy.md](page-taxonomy.md) is the artifact; whether reviewers understand it is a person's confirmation, like the Phase 0 approval-model criterion |
| `wiki/index.md` remains short enough to route | **Met.** 8 links against a cap of 25, no links into `raw/` or `wiki/sources/`, and the cap is now enforced rather than trusted |

Four of seven met, one met at current scale, two require the owner.

## Vault changes made under this phase

Every page migrated onto the new schema mechanically — frontmatter fields added, `updated` bumped,
no prose rewritten:

- 4 concepts, 1 synthesis: `aliases`, `knowledge_status`, `review_needed`
- `wiki/questions/Retrieval Architecture at Ten Thousand Pages.md` created; the open question moved
  out of `wiki/index.md` prose and into a page with provenance, status, and an explicit
  "do not answer this from" section
- `wiki/index.md`: the open-question entry repointed from the source page to the question page
- `wiki/concepts/Markdown-First Retrieval.md`: claim block added; one wikilink rewrapped so the
  link graph can see it
- `wiki/log.md`: operation `schema-20260830-001`

`raw/` untouched — `verify-vault.sh` confirms 10 tracked files unmodified and no content drift.

## Cross-agent verification (Antigravity / Gemini CLI)

None of Phase 2's checks had run under a non-Claude agent before this vault's owner ran one
round. Test prompt and raw report:
[`error-tracking/Phase 2 quality-control test prompt.md`](../../error-tracking/Phase%202%20quality-control%20test%20prompt.md),
[`error-tracking/Phase 2 quality-control-test-report.md`](../../error-tracking/Phase%202%20quality-control-test-report.md).

Same discipline as the three earlier Antigravity portability rounds: every fixture and canary
travels inside the prompt itself, nothing is assumed pre-placed, and the result was independently
re-checked against real repo state rather than taken on the report's word.

**Report claimed PASS. Independent verification confirmed it:**

- `git status --short` after the run matched the pre-run dirty state exactly — nothing from the
  test fixtures (`ZZZ Schema Probe.md`, the two `Token Budgets...` pages, the
  `Cache Invalidation...` question page) survived. `git stash list` empty, `git log` unchanged at
  `987d9c1` — no stray commit.
- The reported `find-duplicates.sh` output for both `"MFR"` and `"Markdown First Retrievals"` was
  hand-traced against the script's actual `norm_title`/`acronym_of`/`title_words` logic —
  finding count, wording, and even the `%-18s` column padding matched exactly. That padding is
  hard to reproduce by paraphrase, which is the strongest evidence these were real runs.
- The three sentences quoted in the `/wiki-trace` task were checked against
  `raw/articles/01-markdown-first-retrieval.md` — verbatim matches, not paraphrase.
- `SECRET_CANARY` never appeared anywhere in the report, full or partial.
- `verify-vault.sh` re-run after the fact: 7/7 sections clean.

**One gap in the report itself, not a violation:** Task D (contradiction handling) never ran
`check-schema.sh` against the two temporary fixture pages before stashing them, so full schema
conformance on those two pages rests only on the `contradiction-not-disputed` lint result, not an
independent schema check. The field that mattered was checked; whether every other field was
present is unverifiable now since the pages are gone. Worth closing in a future round, not enough
to change the verdict.

**What this adds to the exit criteria below:** the automated half of the schema test suite is now
verified under two independent agents (Claude Code and Antigravity/Gemini CLI), not just one. The
specific 8-case manual checklist in [schema-test-suite.md](schema-test-suite.md) — which reuses
the vault's *existing* `raw/articles/01-07` fixtures rather than fresh synthetic ones — is a
related but distinct exercise and is still not run.

## Open items for the pilot owner

1. **Commit or reject** this work plus the still-uncommitted Phase 1 ingest content. The agent does
   not commit.
2. **Supply 13 more sources** for the twenty-source exit criterion, then re-run
   `bash scripts/find-duplicates.sh` and `bash scripts/check-schema.sh` — a duplicate rate measured
   over 6 pages is not yet evidence of anything.
3. **Run the 8 manual test cases** in [schema-test-suite.md](schema-test-suite.md) once, in a
   scratch state. Case 5 (a query with no answer in the vault) is the one most worth running: the
   most likely failure of this vault is a scoped conclusion applied outside its scope. The
   Antigravity round above exercised equivalent scenarios with fresh fixtures — it is evidence the
   mechanism works, not a substitute for these 8 specific cases against the vault's real sources.
4. **Re-run `bash scripts/lock-raw.sh`** after any commit that adds files under `raw/`; new files
   land writable.
5. Phase 1 open items 2–6 from [../session-summary.md](../session-summary.md) are still open,
   including the live slash-command invocation check.

## Deliberately not built

- `entities/`, `architecture/`, `operations/`, `applications/`, `tools/` folders and
  `wiki/overview.md` — no page needs them yet; triggers recorded in
  [page-taxonomy.md](page-taxonomy.md#types-not-yet-created)
- `/wiki-synthesize` and `/wiki-review-source` from plan §4 — no Phase 2 exit criterion depends on
  them, and ingest plus query already cover the ground
- Any auto-fix. Every Phase 2 check reports; none repairs. Auto-fix eligibility is Phase 4
- OKF-side schema changes (`goals/`, `areas/`, accepted-decision enforcement) — Phase 3
