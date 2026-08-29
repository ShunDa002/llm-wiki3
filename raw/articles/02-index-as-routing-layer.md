---
title: The Wiki Index as a Routing Layer
type: article
source_kind: synthetic-test
classification: internal
author: Test Knowledge Lab
published: 2026-07-14
captured: 2026-08-24
ingest_status: new
tags: [index, navigation, llm-wiki]
---

# The Wiki Index as a Routing Layer

> [!warning] Synthetic test source
> This document contains fictional claims for workflow testing.

## Main argument

A Wiki index should be a concise routing document rather than a complete inventory. Its purpose is to direct a reader or an agent toward major concepts, syntheses, open questions, and domain maps.

An index becomes less useful when it copies full summaries or includes every low-value page. Detailed content belongs in the linked pages, while chronological operational history belongs in a separate log.

## Recommended index entry

Each important entry should contain:

- A wikilink to the canonical page
- A one-sentence description
- A meaningful category
- Only the metadata needed for navigation

## Relationship to retrieval

The query workflow should read the index before running broad search. If the index does not provide a useful route, the system may then use filename or full-text search. Repeated search failures should become input to Wiki lint and index improvement.

## Test claims

- `index.md` is a navigation interface, not a copy of the Wiki.
- `log.md` has a separate operational purpose.
- Repeated failure to route a query is a quality signal.
