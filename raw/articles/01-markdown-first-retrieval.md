---
title: Markdown-First Retrieval for Small Knowledge Vaults
type: article
source_kind: synthetic-test
classification: internal
author: Test Research Group
published: 2026-07-10
captured: 2026-08-24
ingest_status: new
tags: [retrieval, markdown, llm-wiki]
---

# Markdown-First Retrieval for Small Knowledge Vaults

> [!warning] Synthetic test source
> This document was created only for testing an LLM Wiki workflow. Its claims are fictional test data and must not be treated as real research.

## Summary

A small knowledge vault can begin with curated index pages, wikilinks, filename search, and full-text search instead of immediately introducing embeddings or a vector database. The simpler approach keeps the system transparent and makes retrieval failures easier to diagnose.

## Proposed operating model

The vault should use `wiki/index.md` as its first navigation layer. A query process reads the index, follows relevant links, and then uses text search if the linked pages are insufficient. Raw evidence is consulted when a critical claim needs verification.

## Claimed benefits

1. Every retrieved item remains readable as a Markdown file.
2. Search behavior can be inspected without a separate database.
3. The team can delay infrastructure until a measurable retrieval problem appears.
4. Git can track changes to both knowledge and navigation.

## Limitations

This approach may lose effectiveness as vocabulary becomes inconsistent or the vault grows beyond what curated routing can manage. The article does not claim that Markdown-only retrieval is sufficient at every scale.

## Test claims

- For a pilot vault below 100 Wiki pages, curated navigation should be tested before semantic retrieval.
- Retrieval tooling should be introduced in response to measured failures.
- Markdown remains the source of truth even if a derived search index is added later.

## Suggested experiment

Create 20 representative questions. Record the expected pages for each question, then measure whether index navigation and full-text search retrieve those pages.
