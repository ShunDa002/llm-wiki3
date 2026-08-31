---
title: Source - Pilot Experiment - Native Retrieval Benchmark
type: source
raw_file: "[[raw/articles/05-experiment-result-native-search]]"
source_id: 70e562f3a42698df9cc4b877a449fa2e1bcf228fc25874900ff345563b6c0d78
source_kind: experiment-result
author: LLM Wiki Pilot Team
classification: internal
captured: 2026-08-24
ingested: 2026-08-24
status: processed
---

# Source - Pilot Experiment - Native Retrieval Benchmark

## What this source is

Synthetic experiment result (source states all measurements are invented for this test pack).
Tests whether index-guided navigation plus full-text search retrieves expected pages in a 42-page
pilot Wiki, using 20 pre-recorded questions.

## Claims taken from it

- 18 of 20 questions retrieved all expected pages; 1 retrieved only one of two expected pages due
  to terminology mismatch; 1 failed because the relevant page was missing from the index under an
  unexpected filename.
- Median retrieval time: 11 seconds. No unsupported answer was accepted on manual review.
- Proposed decision input: keep the current method for the next 30 ingestions, add aliases for
  the terminology-mismatch page, add the missing index entry, re-benchmark at 100 pages.
- Candidate learning: retrieval failures can reveal naming and navigation defects before they
  justify new infrastructure.

## What it changed in the Wiki

- Updated: [[Markdown-First Retrieval]] — added as measured evidence, distinct from the two
  sources that only argued the position without data.

## Not used

This source is also the direct basis for [[Native Retrieval Benchmark]] (OKF experiment) and
[[Select Initial Retrieval Approach]] (OKF decision) — recorded there rather than duplicated
here, since OKF records are execution, not Wiki knowledge.
