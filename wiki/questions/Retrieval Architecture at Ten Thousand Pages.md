---
title: Retrieval Architecture at Ten Thousand Pages
type: question
status: open
classification: internal
tags: [retrieval, scale, open-question]
sources:
  - "[[Source - Open Question - Retrieval at Ten Thousand Pages]]"
created: 2026-08-30
updated: 2026-08-30
---

# Retrieval Architecture at Ten Thousand Pages

## The question

What retrieval architecture gives acceptable precision, recall, latency, and cost at roughly
10,000 pages with multiple agents maintaining the vault concurrently?

## Why it matters

The pilot's accepted decision [[Select Initial Retrieval Approach]] chose Markdown-first
retrieval on evidence gathered below ~100 pages. That decision has a review date, not a
permanent answer. This question is the one that will decide whether the review renews it or
replaces it, and Phase 5 of the implementation plan is where the answer would be measured.

## What the vault knows now

- Markdown-first retrieval holds below ~100 pages, on two sources plus one benchmark —
  [[Markdown-First Retrieval]]
- Adding embeddings early was argued for without a benchmark, cost model, or size threshold —
  [[Semantic Search Enablement Timing]]
- For this pilot's current scale the trade-off is resolved, and only for that scale —
  [[Markdown-First Retrieval vs Early Semantic Search for Small Pilot Vaults]]

## What the vault does not know

Named by the source itself, not inferred —
[[Source - Open Question - Retrieval at Ten Thousand Pages]]:

- No dataset or vault at that scale to measure against
- No stable benchmark at that scale
- No comparison of full-text, metadata, graph, and semantic retrieval at that scale
- No concurrency or index-refresh testing with multiple agents writing
- No cost or latency measurements

## Do not answer this from

- [[Markdown-First Retrieval vs Early Semantic Search for Small Pilot Vaults]] — its scope is
  explicitly below ~100 pages. Borrowing it here is the overgeneralisation failure the scope
  field exists to prevent, and it is the most likely way this question gets answered wrongly.

## Answer

None. `status: open`. Closing this requires Phase 5's query benchmark run at scale, not a
further reading of the sources already in the vault.
