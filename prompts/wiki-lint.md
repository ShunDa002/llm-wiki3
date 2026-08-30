# Workflow: lint the vault

Agent-neutral definition. Claude Code users have `/wiki-lint`; other agents read this file.

**Minimum tools:** read files, search text, run `bash scripts/wiki-lint.sh`,
`bash scripts/check-schema.sh`, `bash scripts/find-duplicates.sh`, and
`bash scripts/verify-vault.sh`. No write tools — lint never repairs.

Invoke the scripts through `bash`, not by path. This repo lives on a filesystem where
`core.fileMode` is false, so a script that looks executable in one clone can arrive as `100644`
in the next.

## Step 1 — run the structural checks

```bash
bash scripts/verify-vault.sh     # enforcement armed? evidence intact? lint clean? policy in sync?
```

`verify-vault.sh` wraps `wiki-lint.sh`, `check-schema.sh`, and `find-duplicates.sh`, and adds the
checks a lint script cannot make about itself. Run one directly for a narrower pass:

```bash
bash scripts/wiki-lint.sh        # page-level structural findings
bash scripts/check-schema.sh     # frontmatter conformance against the approved schema
bash scripts/find-duplicates.sh  # duplicate candidates (advisory — never auto-merge)
```

The script covers what a script can check reliably:

| Finding | Meaning |
|---|---|
| `broken-link` | Wikilink with no matching page |
| `no-sources` | Wiki factual page with no `sources:` field |
| `duplicate-filename` / `near-duplicate` | Two pages competing for one idea |
| `orphan` | No inbound link — unreachable by navigation |
| `index-omission` | Synthesis missing from `wiki/index.md` |
| `no-log-entry` | Source page with no operation record |
| `no-conclusion` / `empty-conclusion` | Experiment that proved nothing yet |
| `no-knowledge-basis` | Decision not traceable to knowledge |
| `single-source-synthesis` | A summary filed as a synthesis |
| `contradiction-not-disputed` | A recorded contradiction that `knowledge_status` does not admit |
| `claim-block-incomplete` | A claim block missing its scope, confidence, or review date |
| `wrapped-wikilink` | A wikilink broken across two lines — renders fine, invisible to every link check |
| `index-bloat` / `index-links-source` / `index-links-raw` | The index has stopped routing and started replicating |

Schema conformance, from `check-schema.sh`:

| Finding | Meaning |
|---|---|
| `missing-field` | A required field from the minimum schema is absent |
| `unknown-field` | An invented field — this is how a schema quietly acquires dialects |
| `bad-value` / `bad-date` | A field outside its allowed set, or a date that is not `YYYY-MM-DD` |
| `type-folder-mismatch` / `unknown-type` | The declared type disagrees with the folder, or is not defined |

## Step 2 — add the semantic layer

A script cannot judge these. Read the pages the script flagged, plus any synthesis changed
recently, and look for:

- Claims on a page that the cited source does not actually support
- Conclusions stated more broadly than the evidence allows
- Contradictions recorded on one page but silently resolved on another
- Concepts that should be one page, or one page that should be two
- Open questions the vault has since answered but never closed

## Report format

```text
LINT REPORT

Enforcement: <armed / NOT armed — from verify-vault.sh>
Structural findings: <n>
<script output, grouped>

Semantic findings:
- <page>: <what is wrong, and the evidence that it is wrong>

Recommended actions:
1. <action> — <who: agent after approval, or owner only>

No repairs performed.
```

Rules:

- Lint recommends. It does not fix. Not even "obvious" fixes — an unambiguous-looking broken link
  is a later-phase auto-fix candidate, not a Phase 1 one.
- Never merge duplicate concepts, resolve a contradiction, or delete a page.
- Distinguish findings the agent may fix after approval (a missing index entry) from findings only
  the owner may touch (anything inside an accepted decision).
- Report false positives you spot in the script's output rather than silently ignoring them. A
  lint nobody trusts gets switched off, and a guard people work around is worse than none.
