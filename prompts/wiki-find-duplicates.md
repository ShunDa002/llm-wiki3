# Workflow: find duplicate and fragmented knowledge

Agent-neutral definition. Claude Code users have `/wiki-find-duplicates`; other agents read this
file. Phase 2 workflow (implementation plan 2.5 and §4 stabilization commands).

**Input:** nothing (scan the vault), or one proposed page title to check before creating it.
**Minimum tools:** read files, search text, run `bash scripts/find-duplicates.sh`. **No write
tools.** This workflow never merges, renames, or deletes anything — merging pages is high-risk and
human-only in every phase of the roadmap.

## Step 1 — run the mechanical checks

```bash
bash scripts/find-duplicates.sh                    # existing collisions across the vault
bash scripts/find-duplicates.sh "Proposed Title"   # before creating a page
```

The script covers the checks a script can make: exact title, normalised filename, aliases,
singular/plural, acronym vs expanded form, significant-word overlap between same-type pages, and
whether an existing page already mentions the proposed title.

Its overlap check is a ratio, not a count — two long titles sharing two ordinary words are not
flagged. That is deliberate: an earlier absolute threshold flagged a concept against the synthesis
written about it, and a duplicate checker that fires on correct structure gets switched off.

## Step 2 — judge each candidate

A mechanical collision is not a duplicate. For each finding decide which case it is:

| Case | Evidence | Right action |
|---|---|---|
| Same idea, two pages | Both define the same thing from the same angle | Propose a merge to the owner |
| Concept and its counterclaim | Pages disagree on a claim | Leave both. Check `knowledge_status: disputed` on each |
| Concept and a synthesis about it | One defines, one compares options | Leave both. Correct structure |
| General idea and a narrower case | One is scoped inside the other | Leave both; add the missing link between them |
| One page, two names | One is an alternate name in use | Propose adding it to `aliases` on the surviving page |

The last row is the cheap fix and the most common one: an alias entry costs one line and prevents
the next ingest from creating the page again.

## Step 3 — report

```text
DUPLICATE REPORT

Mechanical findings: <n>
<script output>

Judgement:
- <page A> / <page B>: <which case above> — <the evidence, not the impression>

Proposed, needs approval:
- Add alias "<name>" to [[<page>]]
- Merge [[<A>]] into [[<B>]]   <- owner only, never the agent

No changes made.
```

Rules:

- Never merge, never rename, never delete. Propose only.
- Never add an alias to a page without approval; it is a schema-field write on an existing page.
- When two pages disagree rather than duplicate, say so explicitly. Reporting a contradiction as a
  duplicate invites a merge that would delete one side of a recorded disagreement — the exact
  failure `## Contradictions` exists to prevent.
- Report false positives you see in the script output. A noisy checker gets ignored, and an ignored
  checker is worse than none.
