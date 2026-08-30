---
title: Wiki Index as Routing Layer
type: concept
status: active
classification: internal
aliases: ["Index as Routing Layer", "Routing Layer"]
tags: [index, navigation, llm-wiki]
sources:
  - "[[Source - The Wiki Index as a Routing Layer]]"
created: 2026-08-24
updated: 2026-08-30
confidence: low
knowledge_status: current
review_needed: false
---

# Wiki Index as Routing Layer

## Definition

`wiki/index.md` is a routing document: it points a reader toward canonical concepts, syntheses,
and open questions with a one-sentence description each. It is not a copy of the vault's content
and should not grow to include every page, full summaries, or operational history.

## Key points

- Each index entry needs only a wikilink, a one-sentence description, and enough metadata to
  route — [[Source - The Wiki Index as a Routing Layer]]
- Operational history belongs in `wiki/log.md`, a separate document with a separate purpose —
  [[Source - The Wiki Index as a Routing Layer]]
- A query should read the index before broad search; a repeated routing failure is itself a
  quality signal that should feed lint — [[Source - The Wiki Index as a Routing Layer]]

## Relationships

- Related: [[Markdown-First Retrieval]] (the index is the first step in that retrieval order)
- Related: [[Wiki Maintenance and Lint Layers]] (routing failures are a lint input)

## Open questions

- None recorded yet.

## Contradictions

None recorded.
