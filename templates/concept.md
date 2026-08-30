---
title: <Concept Name>
type: concept
status: active
classification: public
aliases: []
tags: []
sources:
  - "[[Source - <Name>]]"
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
confidence: low | medium | high
knowledge_status: current | disputed | superseded | uncertain
review_needed: false
---

`aliases` carries every other name this idea is filed under — acronym, expanded form, plural,
the wording a different source used. It is what `scripts/find-duplicates.sh` checks before a
second page gets created for the same idea, so an empty list on a page with a well-known short
name is a duplicate waiting to happen.

`knowledge_status` is not the same field as `status`. `status` is about the page (draft, active,
superseded as a document); `knowledge_status` is about the claim (is it current, disputed,
superseded by better evidence, or uncertain). Set it to `disputed` whenever the Contradictions
section below actually records a disagreement — lint enforces that pairing.

# <Concept Name>

## Definition

One paragraph that explains the concept independently of any single source.

## Key points

- Point, with the source that supports it: [[Source - <Name>]]

## Relationships

- Related: [[<Other Concept>]]
- Contrasts with: [[<Other Concept>]]

## Claim

Optional, and deliberately so — most sentences do not need this. Use one claim block per
high-value claim: anything a decision rests on, anything disputed, anything likely to go stale.
Delete this whole section on a page that has none.

### Support

- [[Source - <Name>]]

### Scope

Where the claim holds, and where it stops. A claim without a scope is how a pilot-sized finding
turns into a general law.

### Confidence

low | medium | high

### Counter-evidence

- None currently recorded.

### Last reviewed

<YYYY-MM-DD>

## Open questions

- Question this concept raises but does not answer. If it is a question the vault should carry
  forward rather than a footnote, give it a page in `wiki/questions/` and link it here.

## Contradictions

Record disagreement here rather than deleting the losing claim. Name both sides and the source
behind each.
