---
title: Pilot Experiment - Native Retrieval Benchmark
type: experiment-result
source_kind: synthetic-test
classification: internal
author: LLM Wiki Pilot Team
experiment_date: 2026-08-20
captured: 2026-08-24
ingest_status: new
tags: [experiment, retrieval, benchmark]
---

# Pilot Experiment: Native Retrieval Benchmark

> [!warning] Synthetic test result
> All measurements in this file are invented for testing the knowledge-to-action loop.

## Question

Can index-guided navigation plus full-text search retrieve the expected pages in a 42-page pilot Wiki?

## Method

The team prepared 20 questions and manually identified the pages expected to support each answer. The query workflow first read `wiki/index.md`, followed explicit wikilinks, and used full-text search only when necessary.

## Synthetic results

- 18 of 20 questions retrieved all expected pages.
- 1 question retrieved only one of two expected pages because the two pages used different terminology.
- 1 question failed because its relevant page was absent from the index and used an unexpected filename.
- Median retrieval time was 11 seconds.
- No unsupported answer was accepted during manual review.

## Interpretation

The result supports continuing with Markdown-first retrieval for the current pilot. It does not establish that the same approach will remain sufficient after substantial growth.

## Proposed decision input

Keep the current retrieval method for the next 30 ingestions. Add aliases to the terminology-mismatch page, add the missing navigation entry, and repeat the benchmark when the Wiki reaches 100 pages.

## Candidate learning

Retrieval failures can reveal naming and navigation defects before they justify new infrastructure.
