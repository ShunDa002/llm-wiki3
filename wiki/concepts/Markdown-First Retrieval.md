---
title: Markdown-First Retrieval
type: concept
status: active
classification: internal
aliases: ["Markdown-First Knowledge Systems", "MFR"]
tags: [retrieval, markdown, llm-wiki]
sources:
  - "[[Source - Markdown-First Retrieval for Small Knowledge Vaults]]"
  - "[[Source - Markdown Retrieval for a Small Wiki]]"
created: 2026-08-24
updated: 2026-08-30
confidence: medium
knowledge_status: disputed
review_needed: false
---

# Markdown-First Retrieval

## Definition

For a small vault (below roughly 100 pages), retrieval should rely on a curated index, wikilinks,
filename search, and full-text search before introducing embeddings or a vector database. Every
retrieved item stays readable as plain Markdown, and Git can track changes to knowledge and
navigation alike. New retrieval tooling is added in response to a measured failure, not on a
schedule.

## Key points

- The query workflow should read `wiki/index.md` first, follow links, then fall back to text
  search — [[Source - Markdown-First Retrieval for Small Knowledge Vaults]]
- Markdown remains the source of truth even after a derived search index is added —
  [[Source - Markdown-First Retrieval for Small Knowledge Vaults]]
- Benchmark method: 20 representative questions, record expected pages per question, measure
  whether navigation and text search retrieve them —
  [[Source - Markdown-First Retrieval for Small Knowledge Vaults]]
- Independently restated by [[Source - Markdown Retrieval for a Small Wiki]] — a second source
  for the same claim, not a second claim. Confidence raised from low to medium on that basis;
  the claim itself is unchanged.
- Measured, not just argued: a 42-page pilot benchmark retrieved all expected pages for 18 of 20
  questions using index navigation plus full-text search.
  See [[Source - Pilot Experiment - Native Retrieval Benchmark]]. The two failures were a
  terminology mismatch and a missing index entry, not a retrieval-method failure.

## Claim

Curated navigation plus full-text search is sufficient retrieval for a vault below roughly 100
pages; embeddings should be added in response to a measured retrieval failure, not in advance.

### Support

- [[Source - Markdown-First Retrieval for Small Knowledge Vaults]] — states the approach and the
  benchmark method
- [[Source - Markdown Retrieval for a Small Wiki]] — independent restatement of the same claim
- [[Source - Pilot Experiment - Native Retrieval Benchmark]] — 18 of 20 expected-page retrievals
  at 42 pages

### Scope

Vaults below roughly 100 pages, maintained by a single agent at a time, with consistent
terminology. The only measurement behind it is one 42-page synthetic benchmark. It says nothing
about 10,000 pages, concurrent agents, or inconsistent vocabulary — see
[[Retrieval Architecture at Ten Thousand Pages]], and do not extend this claim to answer it.

### Confidence

Medium. Two sources plus one measurement, all synthetic, all from this pilot.

### Counter-evidence

- [[Semantic Search Enablement Timing]] asserts the reverse, unconditionally. It supplies no
  benchmark, cost model, or size threshold, which is why it does not lower this claim's confidence
  — but it is recorded, not dismissed, and both pages are `knowledge_status: disputed`.

### Last reviewed

2026-08-30

## Relationships

- Contrasts with: [[Semantic Search Enablement Timing]]
- Related: [[Wiki Index as Routing Layer]]

## Open questions

- At what page count does curated routing stop working? The source itself declines to give a
  number.

## Contradictions

[[Semantic Search Enablement Timing]] argues embeddings should be enabled from day one,
regardless of vault size. This page's source gives a scale condition (below ~100 pages) and a
trigger condition (a measured failure); the other gives neither. Both claims are recorded; neither
is treated as settled. See the synthesis at
[[Markdown-First Retrieval vs Early Semantic Search for Small Pilot Vaults]] for how this bears on
the pilot's actual decision.
