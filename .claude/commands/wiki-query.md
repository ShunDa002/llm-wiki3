---
description: Answer a question from vault knowledge, with citations
argument-hint: <question>
allowed-tools: Read, Grep, Glob
---

Answer: **$ARGUMENTS**

Answer from what the vault records. Not from what you know. If the vault does not contain it,
say so — that is a useful answer, and inventing one destroys the point of a cited knowledge base.

## Retrieval order

1. `wiki/index.md` — start here, always
2. Follow wikilinks from whatever the index points at
3. `Grep` the Wiki for terms from the question
4. Read a small number of the best candidates, not everything that matched
5. Expand into `raw/` only when the Wiki is insufficient, or when a critical claim needs
   verification against original evidence

Create no files. This command is read-only by design.

## Answer conventions

Label where each part of the answer comes from:

```text
Recorded knowledge:
Per [[Knowledge Compilation]], ...

Cross-source inference:
Inferring from [[Concept A]] and [[Concept B]], ...     <- your reasoning, not a recorded claim

Evidence limitation:
The vault does not currently contain evidence for ...

Contradiction:
[[Source A]] supports X, while [[Source B]] supports Y. Not resolved in the vault.
```

Rules:

- Cite every supporting page with a wikilink.
- Mark inference as inference. A conclusion you drew is not a claim the vault makes.
- Surface contradictions rather than picking a winner.
- If the honest answer is "the vault does not know", give it, and say what source would settle it.

## After answering — classify the result

State which one, and why:

```text
Ephemeral   — a lookup, answered and done. Do not save.
Reusable    — a durable comparison, trade-off, or cross-source conclusion. Propose a synthesis.
Actionable  — reusable, and it bears on live work. Propose a synthesis plus an OKF link.
```

Most answers are ephemeral. Saving them all recreates the clipping archive the Wiki exists to
replace.

For `Reusable` or `Actionable`, propose — do not create:

```text
FILE-BACK PROPOSAL

Create:
- wiki/syntheses/<Title>.md

Question it answers:
- <the durable question>

Based on:
- [[Concept A]], [[Concept B]]

Sources:
- [[Source - A]], [[Source - B]]        <- two or more, or it is a summary not a synthesis

Confidence: low | medium | high
Scope limit: <where this stops holding>

OKF relevance (Actionable only):
- [[<project / decision / experiment>]]

Index: <entry to add>
Log:   <operation-id to append>

Approval required.
```

On approval: write the synthesis from `templates/synthesis.md`, add the index entry, append to
`wiki/log.md`, and report the files changed.
