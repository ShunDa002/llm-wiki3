---
title: Native Retrieval Benchmark
type: experiment
status: complete
classification: internal
project: "[[LLM Wiki Pilot]]"
tests_decision: "[[Select Initial Retrieval Approach]]"
started: 2026-08-20
completed: 2026-08-20
---

# Native Retrieval Benchmark

## What is being tested

Whether index-guided navigation plus full-text search can retrieve the expected pages for
representative questions in the pilot Wiki, without embeddings.

## Method

20 questions prepared in advance, with expected supporting pages recorded before running any
query. Each query workflow read `wiki/index.md` first, followed explicit wikilinks, and used
full-text search only when the index and links were insufficient. Manual review checked every
answer for unsupported claims.

## Expected result

Recorded before running (per source): most questions retrieve their expected pages without
embeddings; failures, if any, point to naming or navigation gaps rather than the method itself.

## Metrics

- Questions with all expected pages retrieved: 18 / 20 (90%)
- Questions with partial retrieval: 1 / 20 — two expected pages, one retrieved, due to a
  terminology mismatch
- Questions that failed entirely: 1 / 20 — relevant page absent from the index, unexpected
  filename
- Median retrieval time: 11 seconds
- Unsupported answers accepted on manual review: 0

## Actual result

Matches the expected result: index-guided navigation plus text search worked for the large
majority of questions, and both failures trace to fixable naming/navigation defects, not to a
structural limit of the method.

## Unexpected findings

None beyond the two failure modes above, which the source treats as themselves informative
rather than surprising.

## Conclusion

Markdown-first retrieval (index, wikilinks, text search) is sufficient for this pilot's current
scale. [[Select Initial Retrieval Approach]] is supported by this result. Recommended next
actions from the source: add aliases for the terminology-mismatch page, add the missing index
entry, keep the method for the next 30 ingestions, and re-run this benchmark at 100 pages.

## Possible broader lesson

Retrieval failures can surface naming and navigation defects before they justify new
infrastructure — see [[Wiki Maintenance and Lint Layers]]. Candidate for promotion once observed
across more than one experiment; not promoted yet on a single synthetic result.

Source: [[Source - Pilot Experiment - Native Retrieval Benchmark]]. All measurements are
synthetic test data, stated as such by the source itself — this experiment record exercises the
Phase 1 loop, it is not a real capacity claim about this vault.
