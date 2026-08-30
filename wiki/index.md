---
title: Wiki Index
type: index
updated: 2026-08-30
---

# Wiki Index

Navigation layer, not a content replica. Major entry points with one-sentence descriptions.
If this file starts reading like a table of contents for every page, it has stopped working —
the rules are in [docs/phase-2/page-taxonomy.md](../docs/phase-2/page-taxonomy.md#indexing-rules)
and `scripts/wiki-lint.sh` enforces the two mechanical ones (link cap, no links into `raw/` or
`wiki/sources/`).

## Domains

- [[Markdown-First Retrieval]] — curated navigation and text search before embeddings, below
  ~100 pages; two sources plus one benchmark.
- [[Semantic Search Enablement Timing]] — counterclaim that embeddings are needed from day one;
  no benchmark behind it. Contradicts the entry above; both are recorded.
- [[Wiki Index as Routing Layer]] — what `wiki/index.md` should and should not contain.
- [[Wiki Maintenance and Lint Layers]] — structural vs. semantic lint findings and their fix
  policy.

## Syntheses

- [[Markdown-First Retrieval vs Early Semantic Search for Small Pilot Vaults]] — resolves the
  retrieval-timing question above for this pilot's current scale; does not resolve it in general.

## Open questions

- [[Retrieval Architecture at Ten Thousand Pages]] — the vault has no evidence at that scale.
  Do not answer it from the synthesis above; that is scoped below ~100 pages.

## How to use this vault

- Sources live in `raw/` and are immutable. Their Wiki representation lives in `wiki/sources/`.
- Compiled knowledge lives in `wiki/concepts/`; cross-source conclusions in `wiki/syntheses/`.
- Execution lives in `okf/`. See [[log]] for the operation history.
