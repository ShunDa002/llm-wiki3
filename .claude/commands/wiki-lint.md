---
description: Report vault health findings. Recommends, never repairs.
allowed-tools: Read, Grep, Glob, Bash(bash scripts/wiki-lint.sh), Bash(bash scripts/baseline-metrics.sh), Bash(git status:*)
---

Run `bash scripts/wiki-lint.sh`, then interpret the output. Invoke it through `bash`, not by
path — this environment does not reliably track the executable bit (`core.fileMode: false`), so
a script that looks runnable in this session can come back as `100644` after a fresh checkout.

The script covers what a script can check reliably:

| Finding | Meaning |
|---|---|
| `broken-link` | Wikilink with no matching page |
| `no-sources` | Factual page with no `sources:` field |
| `duplicate-filename` / `near-duplicate` | Two pages competing for one idea |
| `orphan` | No inbound link — unreachable by navigation |
| `index-omission` | Synthesis missing from `wiki/index.md` |
| `no-log-entry` | Source page with no operation record |
| `no-conclusion` / `empty-conclusion` | Experiment that proved nothing yet |
| `no-knowledge-basis` | Decision not traceable to knowledge |
| `single-source-synthesis` | A summary filed as a synthesis |

Then add the semantic layer, which a script cannot judge. Read the pages the script flagged, plus
any synthesis changed recently, and look for:

- Claims on a page that the cited source does not actually support
- Conclusions stated more broadly than the evidence allows
- Contradictions recorded on one page but silently resolved on another
- Concepts that should be one page, or one page that should be two
- Open questions that the vault has since answered but never closed

## Report format

```text
LINT REPORT

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
  is a Phase 4 auto-fix candidate, not a Phase 1 one.
- Never merge duplicate concepts, resolve a contradiction, or delete a page.
- Distinguish findings the agent may fix after approval (a missing index entry) from findings only
  the owner may touch (anything inside an accepted decision).
- Report false positives you spot in the script's output rather than silently ignoring them; a
  lint nobody trusts gets switched off.
