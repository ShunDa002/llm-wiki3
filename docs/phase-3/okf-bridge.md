# Phase 3.1 / 3.2 — OKF object types and allowed relationships

Read this before proposing any `okf/` record or running a `/bridge-*` workflow. Same discipline as
[page-taxonomy.md](../phase-2/page-taxonomy.md): map onto what already exists rather than
restructuring, and do not create a folder before a page needs it.

## 3.1 Object types: map, don't invent

Plan §3.1 lists nine folders. Three already hold real content from Phase 1 and stay exactly as
they are:

| Type | Folder | Holds |
|---|---|---|
| `project` | `okf/projects/` | A commitment with a goal, an owner, and linked decisions/experiments |
| `decision` | `okf/decisions/` | A choice, with knowledge basis and a validation method |
| `experiment` | `okf/experiments/` | A test of a decision, with a required conclusion |

The other six are **not created**, for the same reason `wiki/entities`, `architecture`,
`operations`, `applications`, and `tools` were not created in Phase 2: an empty folder invites
filing by folder instead of by meaning, and none of the three has a page waiting for it yet.

| Type | Would hold | Create it when |
|---|---|---|
| `goal` | A commitment above project level, that more than one project can serve | A second project needs to point at the same goal — one project's goal is just its own `## Goal` section |
| `area` | A standing domain of responsibility, not time-boxed like a project | Projects need grouping by ongoing responsibility rather than by start/end date |
| `debrief` | A structured retrospective at project or experiment close, feeding learning candidates | A project actually closes and needs more than the experiment's own `## Possible broader lesson` section to carry its lessons |
| `deliverable` | A published artifact a project produced | A project produces something that outlives the project page itself |
| `practice` | An adopted, organization-level operating rule, promoted from repeated evidence | `/bridge-promote` finds the same lesson in more than one debrief or experiment — see below, not observed yet |
| `dashboard` | A repeatable status report over OKF/Wiki state | A status question gets asked by hand often enough that automating the answer pays for itself |

**Learning-candidate path, deferred one step:** plan §3.2's `Debrief -> Learning Candidate ->
Synthesis or Practice` chain assumes a `debrief` type that doesn't exist yet. Until it does,
`/bridge-promote` reads the "possible broader lesson" section directly off an `experiment` page —
the same information a debrief would hold, one type earlier in the chain. `okf/practices/` stays
closed regardless: the plan's own §3.5 worked example says not to promote there on a single
result, and nothing in this pilot has cleared that bar yet.

## 3.2 Allowed relationships, as they actually exist in schema

No new frontmatter field was added for this. Every relationship plan §3.2 describes is already
expressible with fields the Phase 1 schema defined:

```text
Project.informed_by        -> Wiki concept or synthesis   (knowledge feeding a project)
Project  "## Decisions"    -> Decision                    (prose link, not frontmatter)
Project  "## Experiments"  -> Experiment                  (prose link, not frontmatter)
Decision.knowledge_basis   -> Synthesis (or concept)       (what a decision rests on)
Decision.validated_by      -> Experiment                   (declared before the result exists)
Experiment.tests_decision  -> Decision                     (the reverse of validated_by, filled in
                                                             from the experiment's side)
```

`validated_by` and `tests_decision` are two ends of the same edge, recorded on both pages by
design — a decision declares what will validate it before the result exists; the experiment
confirms which decision it was testing. Neither script currently checks that the two agree; that
is a natural `wiki-lint`-style structural check for Phase 4, not invented here since no drift has
been observed yet.

`Debrief -> generates -> Learning Candidate` and `Learning Candidate -> may become -> Practice`
are not wired to any field, because neither `debrief` nor `practice` exists — see the table above.

## What `/bridge-*` may and may not touch

Per plan §3.6 and CLAUDE.md's existing prohibition list, the agent may:

- Add a link, a context paragraph, or a proposed decision option/experiment/risk — after approval.
- Read across `wiki/` and `okf/` to build an impact or promotion report.
- Append evidence to a project's `## Status notes` (append-only, dated).

The agent may not, with or without approval requested first:

- Edit a decision once `status: accepted`.
- Edit an experiment once `status: complete` (its `## Conclusion` is final at that point).
- Change a project's `status`, `owner`, `started`, or `review_date`.

`scripts/check-okf-guard.sh` enforces the three "may not" rules mechanically at commit time, the
same way `.githooks/pre-commit` enforces `raw/` immutability — see
[status.md](status.md#semantic-protection-for-okf) for what it checks and how it was tested.
