---
title: Source - The Wiki Index as a Routing Layer
type: source
raw_file: "[[raw/articles/02-index-as-routing-layer]]"
source_id: 169dead146652c99cf67bdec41a2558cc7dd3a535e721d2d2d236de20d961d65
source_kind: article
author: Test Knowledge Lab
classification: internal
captured: 2026-08-24
ingested: 2026-08-24
status: processed
---

# Source - The Wiki Index as a Routing Layer

## What this source is

Synthetic test article describing what `wiki/index.md` should and should not contain.

## Claims taken from it

- The index is a routing document, not a full inventory: entries point to canonical pages,
  syntheses, open questions, and domain maps.
- Full summaries, every page, and operational history belong elsewhere — the last of those in
  `wiki/log.md`, which has a separate purpose from the index.
- The query workflow should read the index before running broad search; if the index does not
  route well, fall back to filename or full-text search.
- Repeated routing failure is a quality signal that should feed lint, not just be tolerated.

## What it changed in the Wiki

- Created: [[Wiki Index as Routing Layer]]

## Not used

The "recommended index entry" bullet list is folded into the concept's Key points rather than
quoted as a separate block — it restates the same routing-document claim in list form.
