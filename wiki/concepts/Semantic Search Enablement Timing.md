---
title: Semantic Search Enablement Timing
type: concept
status: active
classification: internal
aliases: ["Early Semantic Search", "Semantic Search from Day One"]
tags: [semantic-search, embeddings, retrieval]
sources:
  - "[[Source - Semantic Search Should Be Enabled During the Pilot]]"
created: 2026-08-24
updated: 2026-08-30
confidence: low
knowledge_status: disputed
review_needed: true
---

# Semantic Search Enablement Timing

## Definition

Position that a knowledge-vault pilot should build embeddings and semantic retrieval from the
first day, on the claim that semantic similarity is unconditionally superior to lexical and
index-guided search — independent of vault size, vocabulary consistency, cost, or maintenance
capacity.

## Key points

- Rationale given: users phrase questions differently than source wording, so semantic similarity
  can retrieve what lexical search misses —
  [[Source - Semantic Search Should Be Enabled During the Pilot]]
- Strong claim: a pilot without embeddings cannot produce reliable answers —
  [[Source - Semantic Search Should Be Enabled During the Pilot]]
- Evidence gap, stated by the source itself: no benchmark, dataset, cost analysis, or vault-size
  comparison is provided, and "reliability" is not defined —
  [[Source - Semantic Search Should Be Enabled During the Pilot]]

## Relationships

- Contrasts with: [[Markdown-First Retrieval]]

## Open questions

- The source gives no way to test its own claim; what benchmark would settle it?

## Contradictions

Directly opposes [[Markdown-First Retrieval]], which holds curated navigation and text search
should be tried first below ~100 pages, adding embeddings only after a measured failure. This
page's source asserts the reverse unconditionally, but supplies no benchmark, cost model, or size
threshold to weigh against the other side's scale condition. Recorded as unresolved. The evidence
gap here is a material reason the synthesis at
[[Markdown-First Retrieval vs Early Semantic Search for Small Pilot Vaults]] favors the other
side for this pilot specifically, not a general resolution of the disagreement.
