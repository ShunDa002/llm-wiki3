# Phase 2.3 / 2.7 — Page taxonomy and indexing rules

Read this before creating any page. Its whole purpose is to stop one underlying object from
acquiring several page types, which is the fragmentation failure that makes a vault unsearchable.

## The decision rule

Ask these in order and stop at the first yes:

1. Is this an **immutable document** someone else produced? → `source` (`wiki/sources/`)
2. Is this **something the vault does not know**? → `question` (`wiki/questions/`)
3. Is this a **conclusion drawn across two or more sources or pages**? → `synthesis`
4. Can it be **explained on its own, independent of any single source**? → `concept`
5. Is it a **commitment, choice, or piece of work**? → not the Wiki at all; it belongs in `okf/`

If two rules seem to apply, the ordering is the answer, not a tie: a cross-source conclusion is a
synthesis even when it also reads like a concept, because the thing that makes it valuable is the
comparison. If nothing applies, do not invent a type — say so in the ingest plan and stop.

## Types in use

| Type | Folder | Holds | Not for |
|---|---|---|---|
| `concept` | `wiki/concepts/` | A general idea explainable independently of any one source | Restating one source; a comparison |
| `source` | `wiki/sources/` | The Wiki-side representation of one immutable `raw/` file | Any claim the source did not make |
| `synthesis` | `wiki/syntheses/` | A conclusion formed across sources or pages, with scope and confidence | A summary of a single source wearing a hat |
| `question` | `wiki/questions/` | A meaningful uncertainty worth carrying forward | Every passing uncertainty; use a bullet on the concept for those |

`index` and `log` are the two singleton page types (`wiki/index.md`, `wiki/log.md`). They are
infrastructure, not knowledge, and are excluded from every knowledge-level check.

OKF types — `project`, `decision`, `experiment` — are execution records, human-controlled, and out
of scope for Wiki taxonomy decisions. The agent may propose them; it may not change their
semantics.

### Concept vs synthesis, the distinction that actually gets confused

- `[[Markdown-First Retrieval]]` is a concept: it explains an approach, and would still make sense
  if the counterclaim had never been ingested.
- `[[Markdown-First Retrieval vs Early Semantic Search for Small Pilot Vaults]]` is a synthesis: it
  exists only because two positions and a benchmark had to be weighed against each other, and it
  carries a scope the concept does not.

A synthesis is the page a decision cites. That is why it has `based_on`, why lint rejects a
single-source synthesis, and why its `knowledge_status` is the first thing an impact report reads.

### Why a synthesis has no `## Claim` block

The claim block (Support / Scope / Confidence / Counter-evidence / Last reviewed) exists to give a
high-value claim on a *concept* page the structure a synthesis already has by template — its
Question, Evidence, Scope and limits, and Confidence sections are the same thing at page scale.
Adding a claim block to a synthesis would duplicate its own headings.

### Types not yet created

Plan 2.2 lists five more types. None is created, because none has a page waiting for it. Create
one when the trigger below actually fires, and not before — an empty folder invites filing by
folder instead of by meaning.

| Type | Would hold | Create it when |
|---|---|---|
| `entity` | A person, organisation, product, standard, or library | A named thing needs properties and relationships of its own, not a mention inside a concept |
| `architecture` | A structural arrangement, boundary, or data flow | A diagram or component boundary is being cited by more than one page |
| `operation` | A repeatable process — ingest, query, lint, promotion | A process needs a knowledge page rather than living in `prompts/`, which is where it belongs today |
| `application` | A use case showing knowledge being applied | An application recurs across projects; a single use belongs in the `okf/` project |
| `tool` | A tool's capabilities, limits, and integration pattern | A tool's limitations are being cited as evidence in a decision |

`operation` is the one most likely to be created by mistake: this vault's processes are already
single-sourced in `prompts/*.md`, and a knowledge page describing them would be a second copy that
drifts — the exact failure that collapsed `.claude/commands/` into pointers.

---

## Indexing rules

`wiki/index.md` is a **routing layer**. Its job is to get a reader or an agent to the right page in
one hop, not to tell them what the pages say.

It should contain:

- Major domain entry points, one line each
- A one-sentence description per entry — enough to choose, not enough to substitute for the page
- Selected syntheses (all of them, while there are few)
- Key open questions, linked to their `wiki/questions/` page
- Links to domain maps, once domain maps exist

It should not contain:

- Every page. A one-to-one index is a table of contents, and nobody routes with it
- Full summaries or claim text
- Log entries — `wiki/log.md` is the operation history
- Links into `raw/`. The index routes to knowledge; evidence is reached through a source page
- Links into `wiki/sources/`. Same reason, one layer up: cite sources from the page that makes the
  claim, so the scope and status travel with the citation
- Temporary drafts

Two of these are enforced mechanically by `scripts/wiki-lint.sh`: a link cap
(`index-bloat`, 25 links) and no links into `raw/` or `wiki/sources/` (`index-links-raw`,
`index-links-source`). The rest are review judgements — the cap is a smoke alarm, not a design.

An entry earns its place by being a **routing decision someone actually makes**. When a synthesis
is added, it goes in. When a fifth concept about the same domain is added, consider whether the
four should be reachable through one domain entry instead — that is the point at which a domain map
page starts paying for itself, and not before.
