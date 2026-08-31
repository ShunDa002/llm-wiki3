---
title: Select Initial Retrieval Approach
type: decision
status: accepted
classification: internal
project: "[[LLM Wiki Pilot]]"
decision_date: 2026-08-24
review_date: 2026-09-24
knowledge_basis:
  - "[[Markdown-First Retrieval vs Early Semantic Search for Small Pilot Vaults]]"
validated_by: "[[Native Retrieval Benchmark]]"
---

# Select Initial Retrieval Approach

## Context

The implementation plan (2.6) says the MVP should not require embeddings, a vector database,
MCP, or Dataview until specific limitations are measured. The pilot needs one concrete initial
choice to build the closed loop against.

## Decision question

Should the pilot start retrieval with curated navigation and text search, or with embeddings?

## Knowledge basis

- [[Markdown-First Retrieval vs Early Semantic Search for Small Pilot Vaults]] concludes
  Markdown-first retrieval for vaults under ~100 pages, with a benchmark behind it; the opposing
  position has no benchmark, cost model, or size threshold.

## Selected option

Curated navigation and text search (`wiki/index.md`, wikilinks, filename and full-text search).
No embeddings, vector database, or semantic index for the pilot.

## Alternatives considered

- Embeddings from day one — rejected. The one source arguing for this supplies no benchmark,
  cost analysis, or size comparison; see [[Semantic Search Enablement Timing]].

## Expected consequences

Most queries should route through the index and links without full-text fallback. Retrieval
failures, when they occur, should point to naming or navigation defects (fixable via lint) rather
than a structural limit of the method, consistent with [[Wiki Maintenance and Lint Layers]].

## Validation method

[[Native Retrieval Benchmark]] — 20 pre-recorded questions against known expected pages, run
before this decision, cited as its knowledge basis' evidence.

## Review date

2026-09-24, or immediately if lint or query workflows show repeated retrieval failures that
naming fixes do not resolve — per Phase 5.3's staged retrieval-upgrade path.
