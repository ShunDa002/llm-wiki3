# Workflow: lint the vault

Agent-neutral definition. Claude Code users have `/wiki-lint`; other agents read this file.

**Minimum tools:** read files, search text, run `bash scripts/wiki-lint.sh` and
`bash scripts/verify-vault.sh`. No write tools — lint never repairs.

Invoke the scripts through `bash`, not by path. This repo lives on a filesystem where
`core.fileMode` is false, so a script that looks executable in one clone can arrive as `100644`
in the next.

## Step 1 — run the structural checks

```bash
bash scripts/verify-vault.sh     # enforcement armed? evidence intact? lint clean? policy in sync?
```

`verify-vault.sh` wraps `wiki-lint.sh` and adds the checks a lint script cannot make about
itself. Run `bash scripts/wiki-lint.sh` alone if you only want the page-level findings.

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
