# Phase 2.1 — MVP failure review

What actually went wrong in Phase 1, and which Phase 2 change answers it. The rule the plan sets
is that the schema grows **only** in response to an observed failure pattern, so this file is the
justification for every change Phase 2 made — and the reason for the changes it did not make.

Evidence base: the 7-source individual ingest (`raw/articles/01`–`07`), the resulting 4 concepts /
7 source pages / 1 synthesis / 3 OKF records, three rounds of Antigravity boundary testing
(`error-tracking/`), and a direct inspection of every page's frontmatter on 2026-08-30.

---

## Observed failures

### F1 — A source that states no claim had nowhere to live

`raw/articles/07-insufficient-evidence-question.md` poses a question and lists evidence gaps.
Ingest correctly refused to create a concept page: a concept asserts something, and forcing this
source into `templates/concept.md` would have manufactured a claim. But the Phase 1 taxonomy had
no third option, so the question survived only as a prose bullet in `wiki/index.md` — no
frontmatter, no status, no `sources`, no lint coverage, unreachable except through the index, and
invisible to any question like "what does this vault know it does not know?"

**Fix:** `wiki/questions/`, `templates/question.md`, and
`wiki/questions/Retrieval Architecture at Ten Thousand Pages.md`. Ingest now names this case
explicitly rather than leaving it to judgement.

### F2 — Contradictions were recorded in prose and nowhere else

The 01-vs-03 retrieval contradiction is recorded well, on both concept pages, with both sources,
neither claim overwritten. But it was recorded *only* as prose. No field said "this claim is
disputed", so the disagreement was legible to a human reading the page and invisible to every
query, filter, and future impact report. A decision could cite a disputed page without anything
signalling it.

**Fix:** `knowledge_status: current | disputed | superseded | uncertain`, plus the
`contradiction-not-disputed` lint check that pairs the field to the section. The two sides of the
retrieval contradiction are now `disputed`; the counterclaim page, which has an admitted evidence
gap, is also `review_needed: true`.

### F3 — The index linked into the evidence layer

The open-question entry pointed at `[[Source - Open Question - Retrieval at Ten Thousand Pages]]`.
Plan 2.7 says the index must not contain raw files; linking a source page is the same mistake one
layer up — routing traffic into evidence instead of into knowledge, which is where the scope,
status, and relationships live.

**Fix:** `index-links-source` and `index-links-raw` lint checks plus a link cap, and the entry
repointed at the new question page. This check found a real defect on its first run against the
live vault, which is the only evidence that a lint rule is worth having.

### F4 — Schema drift was already present after one phase, and nothing was watching

Found by dumping every page's frontmatter and comparing it to the schema in `CLAUDE.md`:

- Every synthesis page carries `tags`, which the Synthesis line of the schema did not list.
- Source pages use `source_kind: research-note` and `source_kind: experiment-result`; the template
  offered `article | notes | transcript | webpage`.

Neither is damaging on its own. Both are exactly how a "minimum schema" acquires dialects: no
single page looks wrong, and by the time anyone tries to query across the vault the fields no
longer agree. Nothing in Phase 1 compared pages to the schema at all.

**Fix:** `scripts/check-schema.sh`, which validates required fields, enum values, and date
formats — and, more importantly, **rejects fields not on the approved list**. The two drifts above
were resolved by correcting the schema (`tags` added to Synthesis, the two real `source_kind`
values accepted), not by rewriting the pages, because in both cases the pages were right and the
schema was incomplete.

### F5 — Duplicate detection existed only as an instruction

Ingest told the agent to check exact title, normalised title, singular/plural, and acronym form by
hand. It worked — source 04 was correctly recognised as restating source 01, and no duplicate
concept was created. But an instruction is not a control: it leaves no artifact, cannot be run
before a *human* creates a page, cannot be re-run against the whole vault, and its success depends
on the agent that happened to execute it.

**Fix:** `scripts/find-duplicates.sh` implementing all seven checks from plan 2.5, an `aliases`
field giving the check something to match against, and `/wiki-find-duplicates` for running it
before page creation.

### F6 — Provenance was page-level, never claim-level

Every factual page cites its sources, which satisfies the Phase 1 rule. But the scope of a
specific claim lived in prose. The synthesis holds only below ~100 pages; that limit is stated in a
paragraph, so nothing stops a future query from applying it at 10,000 pages — the single most
likely way this vault produces a confidently wrong answer.

**Fix:** the optional `## Claim` block (Support / Scope / Confidence / Counter-evidence / Last
reviewed) with a lint check for incomplete blocks, and the `## Do not answer this from` section on
question pages, which names the tempting-but-out-of-scope page explicitly. Deliberately optional:
requiring a claim block per sentence would make pages unreadable and get the format abandoned.

### F7 — One live wikilink was invisible to every link-based check

`wiki/concepts/Markdown-First Retrieval.md` cited
`[[Source - Pilot Experiment - Native Retrieval Benchmark]]` with the link wrapped across two
lines. Obsidian renders that correctly, so it looked fine to a reader. The link graph is built line
by line, so to lint it did not exist: no `broken-link` finding, no inbound-link credit, no orphan
detection through it. A whole class of link defect was silently unreachable by the tooling.

**Fix:** the `wrapped-wikilink` lint check, and the link on that page rewrapped so it fits one
line. Found by reading the page while adding its claim block, not by any check — which is the
argument for the check.

---

## Found while implementing Phase 2

One defect of the same class as the §3a drift, caught by writing a new workflow rather than by
review: `scripts/check-command-pointers.sh` required the exact string
`Bash(bash scripts/<x>.sh)` in a command's `allowed-tools`. A script that takes an argument needs
`Bash(bash scripts/<x>.sh:*)`, so the checker would have rejected the only entry that actually
works, and the cheapest way to satisfy it would have been to grant a permission that does not
run. Changed to a prefix match.

---

## Failure patterns from plan 2.1 that were NOT observed — and the changes not made

| Pattern | Observed? | Consequence |
|---|---|---|
| Duplicate page creation | No — near-duplicate 04 was caught | Detection hardened anyway (F5), because the control was an instruction, not a mechanism |
| Poor names | No | No renaming rules added. Renaming is human-only regardless |
| Excessive fragmentation | No — 4 concepts from 7 sources | No merge tooling built |
| Oversized pages | No — largest page is ~50 lines | No size lint, no splitting rules |
| Weak or missing provenance | Page-level fine, claim-level absent | Claim block added (F6), not required |
| Unsupported conclusions | No | `/wiki-trace` added to *check* this, changing nothing about page structure |
| Excessive index growth | No — 6 entries | Cap set at 25 links so the failure is detected before it arrives |
| Missing OKF relevance | No — the synthesis reached a decision and an experiment | No bridge tooling; that is Phase 3 |
| Unnecessary file creation | No — source 07 correctly produced no concept | Reinforced as an explicit ingest rule |
| Incorrect confidence assignment | No | No confidence rubric written |
| Inconsistent link direction | No | No link-direction rules |
| Semantic drift during updates | No — updates were additive | No diff-review tooling |

**Taxonomy deliberately not expanded.** Plan 2.2 lists `entities/`, `architecture/`,
`operations/`, `applications/`, and `tools/`. None has a page waiting for it: nothing in seven
sources needed to describe a person, organisation, structural arrangement, or specific tool as its
own object. Empty folders are worse than absent ones, because the next agent files by folder
rather than by semantics. Add each one when a real page has nowhere else to go — the trigger for
each is recorded in [page-taxonomy.md](page-taxonomy.md#types-not-yet-created).

`wiki/overview.md` was also skipped: with four concepts, a domain-map page between the index and
the concepts is a second index to keep in sync.
