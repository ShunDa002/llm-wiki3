---
title: Markdown-First Retrieval vs Early Semantic Search for Small Pilot Vaults
type: synthesis
status: active
classification: internal
aliases: ["Markdown Retrieval vs Vector Retrieval for Small Vaults"]
tags: [retrieval, markdown, semantic-search]
sources:
  - "[[Source - Markdown-First Retrieval for Small Knowledge Vaults]]"
  - "[[Source - Markdown Retrieval for a Small Wiki]]"
  - "[[Source - Semantic Search Should Be Enabled During the Pilot]]"
  - "[[Source - Pilot Experiment - Native Retrieval Benchmark]]"
based_on:
  - "[[Markdown-First Retrieval]]"
  - "[[Semantic Search Enablement Timing]]"
created: 2026-08-24
updated: 2026-08-30
confidence: medium
knowledge_status: current
review_needed: false
---

# Markdown-First Retrieval vs Early Semantic Search for Small Pilot Vaults

## Question

For a pilot vault under 100 pages, should retrieval start with curated navigation and text
search, or with embeddings from day one?

## Conclusion

Start with curated navigation and text search. Add embeddings only after a measured retrieval
failure that the simpler methods cannot fix. This is the position with a scale condition, a
trigger condition, and a benchmark result behind it; the opposing position has neither a
condition nor a benchmark.

## Comparison

| Option | Strengths | Weaknesses | When it applies |
|---|---|---|---|
| Markdown-first (index, links, text search) | Transparent, Git-trackable, no added infrastructure, measured at 18/20 on a 42-page benchmark | Two of twenty questions still failed — on naming/index gaps, not the method | Below ~100 pages, or until a measured failure appears |
| Embeddings from day one | May catch phrasing mismatches lexical search misses | No benchmark, cost model, or size threshold offered; "reliability" undefined | Unclear — the source argues it applies unconditionally, which the evidence does not support |

## Evidence

- [[Source - Markdown-First Retrieval for Small Knowledge Vaults]] and
  [[Source - Markdown Retrieval for a Small Wiki]] independently state the same scale- and
  trigger-conditioned position.
- [[Source - Pilot Experiment - Native Retrieval Benchmark]] measured it: 18 of 20 questions
  retrieved all expected pages; the 2 failures trace to a terminology mismatch and a missing
  index entry, not to the retrieval method itself.
- [[Source - Semantic Search Should Be Enabled During the Pilot]] argues the opposite
  unconditionally, but by its own admission supplies no benchmark, cost analysis, or size
  comparison.

## Scope and limits

This holds for a vault below roughly 100 pages with a single agent. It says nothing about
10,000-page or multi-agent retrieval — see the open question in `wiki/index.md` from
[[Source - Open Question - Retrieval at Ten Thousand Pages]], which this synthesis deliberately
does not attempt to answer. It also does not resolve whether embeddings become worthwhile
*before* a failure occurs — only that no evidence here shows they are needed before one does.

## Confidence

Medium. Two independent sources plus one benchmark support the conclusion; all four are synthetic
test fixtures rather than real production data, which caps confidence below "high" regardless of
internal consistency.
