# Phase 3 status — formal OKF integration

Date: 2026-08-30. Automation level: **2** — the agent proposes plans and executes approved ones.

Phase 3 builds the bridge between Wiki knowledge and OKF execution without inventing OKF types or
schema fields no page needs yet. Full detail in
[okf-bridge.md](okf-bridge.md).

## What was built

| Plan task | Delivered |
|---|---|
| 3.1 Define OKF object types | [okf-bridge.md](okf-bridge.md#31-object-types-map-dont-invent) — 3 types mapped onto existing folders, 6 deferred with a named trigger each, same discipline as Phase 2's page-taxonomy deferrals |
| 3.2 Define allowed relationships | [okf-bridge.md](okf-bridge.md#32-allowed-relationships-as-they-actually-exist-in-schema) — documented against fields that already exist; no schema change |
| 3.3 Build `/bridge-apply` | `prompts/bridge-apply.md` + `.claude/commands/bridge-apply.md` |
| 3.4 Build `/bridge-impact` | `prompts/bridge-impact.md` + `.claude/commands/bridge-impact.md` |
| 3.5 Build `/bridge-promote` | `prompts/bridge-promote.md` + `.claude/commands/bridge-promote.md` |
| 3.6 Protect OKF semantics | `scripts/check-okf-guard.sh`, wired into `.githooks/pre-commit` (hard block) and `scripts/verify-vault.sh` (hard-fail section) — same portable, git-level pattern as `raw/`'s immutability hook |

`scripts/check-command-pointers.sh`'s workflow list now covers the three bridge commands, so the
existing pointer/tool-permission check applies to them for free. `scripts/test-portability.sh`
gained 4 checks (37 → 41): blocks editing an accepted decision, blocks editing a completed
experiment, blocks changing a project's protected field, and — the negative case — still allows
appending a status note. All pass; `verify-vault.sh` reports 8/8 sections clean.

## Known blind spot

`check-okf-guard.sh` compares against `HEAD`. A file that has never been committed has no
baseline, so it is skipped — and **the live `okf/` pages are currently untracked** (`git ls-files
-- okf` returns only four `.gitkeep` files). The guard is therefore **inert against the real
vault's decision, experiment, and project pages right now**, and the 4 passing regression cases in
`test-portability.sh` prove only that it works once a baseline exists, which is what they
construct.

This is the same shape as the `raw/` blind spot that let commit `f38689b` land during round-2
Antigravity testing: a check that diffs against tracked history cannot see a file mutated before
its first commit. It was found while writing the Phase 3 test prompt, by checking whether the
guard actually fires against live content rather than assuming the green test suite covered it.

Unlike `raw/`, there is no second fix available in script form. The `raw/` case was closable
because `wiki/sources/` independently records a `source_id` hash to compare against; a decision's
`status: accepted` lives only in the decision file itself, so there is nothing external to
diff against. **Committing an `okf/` baseline is the fix** — the same fix `5c5ad09` was for `raw/`
— and it is a pilot-owner action, since the agent does not commit. Until then:

- A change to an already-committed accepted decision is blocked. (None exist yet.)
- A *first* commit of an `okf/` page is allowed regardless of content, as git reports it `Added`.
  The pilot owner's diff review is the only control on that first commit, exactly as it was for
  `raw/` before `5c5ad09`.

## Why six OKF types were not created

`goals/`, `areas/`, `debriefs/`, `deliverables/`, `practices/`, `dashboards/` are not created. Same
reasoning Phase 2 applied to `entities/`, `architecture/`, `operations/`, `applications/`,
`tools/`: an empty folder invites filing by folder instead of by meaning, and none of the six has
a page waiting for it. Each has a named creation trigger in
[okf-bridge.md](okf-bridge.md#31-object-types-map-dont-invent). The most consequential
consequence: `/bridge-promote`'s only open destination is `wiki/syntheses/` — `okf/practices/`
stays closed, matching the plan's own §3.5 worked example ("Do not promote to okf/practices/
yet").

## Demonstrated against real content, not synthetic fixtures

Both read-only workflows were run for real against the vault's actual Phase 1 closed loop —
deliberately, so the first proof of each isn't a made-up example.

### `/bridge-impact` on the synthesis that already backs a decision

```text
IMPACT REPORT

Changed knowledge:
- [[Markdown-First Retrieval vs Early Semantic Search for Small Pilot Vaults]]
  (knowledge_status: current)

Potentially affected:
- [[Select Initial Retrieval Approach]] (rank: direct)
  - cited via knowledge_basis; the decision's "Selected option" rests on this synthesis's claim
- [[LLM Wiki Pilot]] (rank: direct)
  - cited via informed_by; the project's first decision runs on this synthesis
- [[Native Retrieval Benchmark]] (rank: transitive)
  - not a direct citation of the synthesis, but validates the decision that is

Recommended actions:
1. Review [[Select Initial Retrieval Approach]] — no action needed while knowledge_status stays
   current.
2. Do not change status automatically.
3. No review note added — nothing here changed, this is a real-content dry run.
```

This is a real, existing citation chain, not a planted defect. The plan's exit criterion asks for
"a deliberately planted affected decision" — a distinct exercise, closed separately in the
cross-agent round below.

### `/bridge-promote` on the one experiment that has a candidate lesson

```text
PROMOTION PROPOSAL

Source:
- [[Native Retrieval Benchmark]]

Candidate lesson:
- Retrieval failures can surface naming and navigation defects before they justify new
  infrastructure.

Evidence count:
- 1 observation found (this experiment). No other okf/experiments/*.md or debrief-shaped page
  makes the same claim.

Recommended destination:
- Defer. Reason: single observation, no corroborating evidence.

Confidence:
- Low — the experiment page states its own metrics are synthetic test data, not a real capacity
  claim.

Limitation:
- One vault, one experiment, synthetic measurements.

Do not promote to okf/practices/. That folder does not exist yet — see okf-bridge.md.
```

This matches what the experiment page already says about itself ("not promoted yet on a single
synthetic result"). The workflow declining to promote on its own reading, not just repeating the
page's self-assessment, is the actual test of whether §3.5's five questions do useful work here —
they do: "supported by more than one observation?" answers no on a real count, not an assumption.

## Cross-agent verification (Antigravity / Gemini CLI)

Date: 2026-08-31. Test prompt:
[`error-tracking/Phase 3 okf-integration test prompt.md`](../../error-tracking/Phase%203%20okf-integration%20test%20prompt.md).
Report: [`error-tracking/Phase 3 okf-integration-test-report.md`](../../error-tracking/Phase%203%20okf-integration-test-report.md).

Same discipline as the four earlier Antigravity rounds: fixtures travel inside the prompt, and the
result was re-checked against real repo state rather than taken on the report's word. Nine tasks
covering every Phase 3 element, including the blind spot above — the prompt made *overstating* that
control an explicit FAIL condition.

**Report claimed PASS. Independent verification confirmed it**, on evidence that cannot be
paraphrased:

- **The planted-defect drill was real.** The quoted `git diff` header read
  `index 79a1ee0..16fb391`. Both blob hashes were reproduced here: `git rev-parse HEAD:<synthesis>`
  gives `79a1ee0011c9…`, and `git hash-object` on the same file with only `knowledge_status`
  changed to `disputed` gives `16fb39133b07…`. A summarised or invented run cannot produce a
  matching pair of git object IDs. This is what closes the impact-drill exit criterion above.
- **Fixture integrity was real.** Fixture 2's reported sha256
  (`41815975cef7…`) was reproduced byte-for-byte by rebuilding the fixture from the prompt's own
  code block — so the "accepted decision untouched" claim in task F.4 is verifiable, not asserted.
- **Cleanup was complete.** Current `git status --short` differs from the report's stated pre-run
  state by exactly one line: the report file itself. `HEAD` still `f30c6ea`; `find . -name 'ZZZ
  Test*'` empty; the real accepted decision back to sha256 `3907d07d…` with `status: accepted`.
- **The blind spot was confirmed honestly, not glossed.** Task E.2 modified the real accepted
  decision in the working tree and reported that `check-okf-guard.sh` and `verify-vault.sh` both
  stayed clean, because the file is untracked. That is the documented behaviour, and reporting it
  as protection would have been the prompt's designated FAIL.
- **Every quoted script output matches the scripts' actual format strings** — the three `BLOCKED:`
  lines (including `(M)` and the `('alice' -> 'bob')` quoting), both
  `check-command-pointers.sh` `PROBLEM:` lines, and `check-schema.sh`'s header down to its two
  blank lines. Task H was independently re-run here against rebuilt fixtures: clean, exit 0.
- Secret canary: zero occurrences in the report, full or partial. Project `owner` unchanged.

### What the PASS does *not* establish

1. **`bridge-apply`'s write path is still unexecuted anywhere.** Task F correctly stopped at the
   plan and correctly refused the accepted target, which is what was asked — but step 4 of
   `prompts/bridge-apply.md` (update the target, append to `wiki/log.md`, re-run
   `check-schema.sh`) has never run. Open item 4 stands.
2. **Task E.3 is confirmation, not new coverage.** It reconstructed by hand what
   `test-portability.sh`'s four `okf-guard` cases already build in a scratch repo. Useful — it
   shows the guard behaves identically under a different agent and shell — but it says nothing
   about the live vault, where the guard remains inert. Open item 1 stands, unchanged and still
   the highest-value item here.
3. **The portability question task A asked was never actually exercised.** Antigravity ran on
   Linux with GNU coreutils, the same platform class as the Claude Code environment, so "no
   dialect anomalies" is a weak signal. It did prompt a real find, though: this phase's own new
   test block used `sed -i`, which fails on BSD/macOS sed (where `-i` requires an argument).
   Fixed to `sed … > tmp && mv`. Two older instances remain in `scripts/test-schema.sh` from
   Phase 2 — pre-existing, left for the owner to decide on rather than swept into this phase.

### One accidental win

The prompt's Fixture 1 declares `validated_by: "[[Native Retrieval Benchmark]]"` while Fixture 3
declares `tests_decision: "[[ZZZ Test - Adopt Per-Turn Budget Cap]]"` — an asymmetric pair, written
by copy-paste rather than by design. Task I found it and correctly reported that no script flags
it, which turned an intended documentation check into a genuine planted-defect test of the
reciprocity gap. Data point worth keeping: of the first two decision/experiment pairs this vault
has ever held, one was already asymmetric. That strengthens the case for the Phase 4 reciprocity
check without justifying building it now.


## Exit criteria

| Criterion | Status |
|---|---|
| At least three Wiki syntheses linked to OKF records | **Not met — owner action.** One synthesis exists in this vault, and it is linked (see above). The mechanism supports any number; the sources to produce two more do not exist yet, same shape as Phase 2's 20-source criterion |
| At least one decision is traceable to sources through a synthesis | **Met.** `[[Select Initial Retrieval Approach]]` → `knowledge_basis` → the synthesis → its two source concepts → their `wiki/sources/` pages → `raw/`. Real, unbroken, walkable with `/wiki-trace` |
| At least one experiment result returns to the Wiki | **Met, from Phase 1.** `[[Native Retrieval Benchmark]]`'s conclusion is cited back onto `[[Wiki Maintenance and Lint Layers]]` |
| Impact analysis identifies a deliberately planted affected decision | **Met, under cross-agent verification.** Run by Antigravity/Gemini CLI: the synthesis's `knowledge_status` was flipped to `disputed` in the working tree and the re-run report flagged it against both dependent records. The plant is independently verified — the quoted diff's blob hashes (`79a1ee0..16fb391`) were both reproduced here, which a paraphrased report cannot fake. See [Cross-agent verification](#cross-agent-verification-antigravity--gemini-cli) |
| No semantic OKF changes occur without approval | **Met, mechanically now.** `ask` on `okf/**` gates Claude Code; `scripts/check-okf-guard.sh` gates any agent at commit time — see the 4 regression cases in `test-portability.sh` |
| Promotion distinguishes local observations from general knowledge | **Met.** The `/bridge-promote` run above declines promotion on an explicit observation count, not a guess |

4 of 6 met, 1 met carrying over from Phase 1, 1 needs the owner (more sources). The
planted-defect impact drill was closed by the cross-agent round below.

## Open items for the pilot owner

1. **Commit an `okf/` baseline.** Until the decision, experiment, and project pages are tracked,
   `check-okf-guard.sh` has nothing to diff against and is inert against them — see
   [Known blind spot](#known-blind-spot). This is the highest-value item here, and it is the same
   fix `5c5ad09` was for `raw/`.
2. **Supply sources that produce a second and third synthesis**, so the "three syntheses linked to
   OKF" criterion has something real to measure instead of one.
3. **Run a planted-defect `/bridge-impact` drill**: change a synthesis's `knowledge_status` to
   `disputed` in a scratch state, confirm the report calls it out against the decision that cites
   it, then discard the scratch change. Same discipline as `scripts/test-wiki-lint.sh`'s planted
   defects, not yet done for this workflow specifically.
4. **Run `/bridge-apply` live at least once.** It is built and documented with a worked example
   (`prompts/bridge-apply.md`) but not executed against real content in this session — doing so
   safely means either a genuinely new project/decision link or a scratch fixture, and neither
   was fabricated just to exercise it. Same honest gap pattern as the still-open "run
   `/wiki-ingest` etc. live" item from Phase 1/2.
5. Phase 1 and Phase 2 open items in [../session-summary.md](../session-summary.md) are still
   open and unaffected by this phase.

## Deliberately not built

- `okf/{goals,areas,debriefs,deliverables,practices,dashboards}/` — see above.
- Any check that `Decision.validated_by` and `Experiment.tests_decision` agree with each other.
  No drift has been observed between the two on any real page; inventing the check now would be
  guessing at a failure mode, the same restraint Phase 2 applied to the 12 unobserved patterns in
  `mvp-failure-review.md`. Natural fit for Phase 4's OKF lint layer if it ever fires for real.
- OKF lint (goal without review date, decision without knowledge basis, etc.) — explicitly Phase
  4 in the plan, not this phase.
