# Phase 0 deliverable: pilot scope statement

Status: active
Date: 2026-08-24
Phase: 0 (Controls, scope, and baseline)

## Pilot owner

| Role | Person | Responsibility |
|---|---|---|
| Pilot owner / reviewer | shonda_tay@wiwynn.com | Approves medium-risk plans, performs all high-risk operations, reviews every diff, owns rollback |

There is exactly one accountable reviewer. If the owner changes, update this table before the
next ingest.

## Pilot domain

```text
Topic: LLM-assisted knowledge management
OKF project: Build personal LLM Wiki
Decision: Select initial retrieval approach
Experiment: Compare native search and grep-based search
```

Chosen because the pilot's subject matter is the pilot itself: the sources are public technical
writing, the decision is real and pending, and a wrong answer costs nothing outside this vault.

## Boundaries

In scope:

- One narrow domain, 10 to 20 representative sources, added by the owner into `raw/`.
- One active OKF project, one decision, one experiment.
- This vault only (`/c/Data/llm-wiki3`).

Out of scope for the pilot:

- Migrating any existing vault or note collection.
- Wiwynn internal, customer, or supplier material.
- Any second domain, second project, or batch ingestion.
- Embeddings, vector database, MCP, Dataview, schedulers.

## Data expectations

- Source classification: `public` and `internal` only during the pilot. See
  [privacy-policy.md](privacy-policy.md).
- No confidential or restricted material enters the pilot vault.
- No secrets, credentials, keys, tokens, or passwords, ever.

## Phase 0 completion means

Controls exist and are tested. It does not mean knowledge work has started. Phase 1 begins only
after the exit criteria in [phase-0-report.md](phase-0-report.md) are all met.

## Related deliverables

- [risk-matrix.md](risk-matrix.md)
- [privacy-policy.md](privacy-policy.md)
- [git-recovery-checklist.md](git-recovery-checklist.md)
- [baseline-metrics.md](baseline-metrics.md)
- [phase-0-report.md](phase-0-report.md)
