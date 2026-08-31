# Workflow: promote a lesson from local observation to reusable knowledge

Agent-neutral definition. Claude Code users have `/bridge-promote`; other agents read this file.
Phase 3 workflow (implementation plan §3.5). Read
[docs/phase-3/okf-bridge.md](../docs/phase-3/okf-bridge.md) first — `okf/practices/` does not
exist yet in this vault, and `debrief` isn't a type here either; see below for what that changes.

**Input:** an `experiment` page (the plan also allows a `debrief`; this vault has none — see
[okf-bridge.md](../docs/phase-3/okf-bridge.md#31-object-types-map-dont-invent)).
**Minimum tools:** read files, search text. **No write tools** — this produces a proposal; a
synthesis page is created only after separate approval, following the normal `wiki/` plan-first
rule.

## Step 1 — read the candidate lesson

Read the input experiment's `## Possible broader lesson` section. If it says the lesson is local
to the project, or explicitly not yet promoted, that is evidence, not something to override.

## Step 2 — evaluate against plan §3.5's five questions

| Question | Where to look |
|---|---|
| Is the lesson specific to one project? | The experiment's `project` field and prose |
| Is it supported by more than one observation? | Search other `okf/experiments/*.md` and any `debrief`-shaped notes for the same claim |
| Does it agree with existing research? | Search `wiki/concepts/` and `wiki/syntheses/` for a page that already makes a related claim |
| Is it explanatory knowledge or an operating practice? | Explanatory → `wiki/syntheses/`. An operating rule → `okf/practices/`, which does not exist in this vault yet, so decline that destination regardless of the answer and say so |
| What is the confidence, and what limits its scope? | The experiment's `## Metrics` and any stated sample size or synthetic-data caveat |

## Step 3 — report

```text
PROMOTION PROPOSAL

Source:
- [[<Experiment>]]

Candidate lesson:
- <one sentence>

Evidence count:
- <n> observation(s) found: [[<Experiment A>]], [[<Experiment B>]], ...

Recommended destination:
- wiki/syntheses/ (only option currently open — okf/practices/ does not exist in this vault)
  OR
- Defer. Reason: <e.g. single observation, no corroborating evidence>

Confidence:
- <low | medium | high>, and why

Limitation:
- <sample size, synthetic-data caveat, scope>

Do not promote to okf/practices/. That folder does not exist yet — see
docs/phase-3/okf-bridge.md.
```

Rules:

- One observation is not evidence of a general pattern. Say so and decline, rather than promoting
  on a single synthetic experiment — this vault's own experiment pages already say this about
  themselves; take that at face value, don't talk the record into more than it claims.
- A proposal is not a write. Creating the synthesis, if approved, follows `/wiki-find-duplicates`
  before anything is created — this workflow only proposes, it does not run that check itself.
