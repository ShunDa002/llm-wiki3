# Phase 0 deliverable: risk matrix

Date: 2026-08-24
Phase: 0. High-risk rows stay human-approved for the whole roadmap, not only Phase 0.

## Classification

### Low risk — agent may act, then report

| Operation | Enforcement |
|---|---|
| Reading files | Allowed |
| Searching filenames or text | Allowed |
| Generating an ingest plan | Allowed (Phase 1+) |
| Creating a report in temporary output | Allowed, outside the vault |
| Checking metadata | Allowed |
| Identifying broken links | Allowed |

### Medium risk — plan first, execute only the approved plan

| Operation | Enforcement |
|---|---|
| Creating a Wiki page | Plan, approve, execute |
| Appending a source reference | Plan, approve, execute |
| Updating `wiki/index.md` | Plan, approve, execute |
| Appending to `wiki/log.md` | Plan, approve, execute |
| Adding a link to a draft OKF record | Plan, approve, execute; `ask` rule on `okf/**` |

### High risk — prohibited for the agent, human performs

| Operation | Enforcement |
|---|---|
| Editing accepted decisions | Policy in `CLAUDE.md`; `ask` on `okf/**` |
| Changing goal scope | Policy |
| Changing project status | Policy |
| Moving or renaming files | `ask` on `Bash(mv:*)` |
| Rewriting multiple pages | Policy: plan required above five files |
| Deleting files | `ask` on `Bash(rm:*)`, `deny` on `Bash(rm -rf:*)` |
| Modifying schemas or templates | `ask` on `templates/**` |
| Vault-wide refactoring | Policy |
| Committing or pushing changes | `ask` on `git commit`, `deny` on `git push` |
| Accessing external systems | Policy; approval per action |

### Prohibited outright — no approval path

| Operation | Enforcement |
|---|---|
| Any write, move, or delete under `raw/` | `deny` on `Write`/`Edit` of `./raw/**` plus PreToolUse hook `.claude/hooks/protect-raw.sh` covering shell-mediated writes |
| Committing secrets or restricted data | [privacy-policy.md](privacy-policy.md) |

## How enforcement is wired

Two independent layers, so a single misconfiguration does not open `raw/`:

1. `permissions.deny` in `.claude/settings.json` — blocks the file-editing tools by path.
2. `.claude/hooks/protect-raw.sh` — PreToolUse hook. Denies `Write`/`Edit`/`MultiEdit`/
   `NotebookEdit` whose target path contains `raw/`, and denies `Bash` commands that name
   `raw/` together with a mutating verb (redirect, `rm`, `mv`, `cp`, `tee`, `truncate`,
   `touch`, `mkdir`, `chmod`, `dd`, `ln`, `sed -i`, `perl -i`, and similar).

Reads of `raw/` stay allowed — that is the point of the folder.

Verified deny cases (see [phase-0-report.md](phase-0-report.md) for the run):
`Write raw/...`, `echo > raw/...`, `rm -rf raw/...`, `sed -i ... raw/...`.
Verified allow cases: `Write wiki/...`, `grep -r foo raw/`, `rm /tmp/junk`.

## Known limits of this control

- The Bash guard is a heuristic on command text. An obfuscated command (base64, a variable
  holding the path, a script written elsewhere then executed) can evade it. The `deny` path
  rules and Git history are the backstop, and the pilot owner reviews every diff.
- Permission rules apply to this project directory. An agent started with a different working
  directory or with `bypassPermissions` does not inherit them.
- Nothing here prevents a human mistake. Recovery, not prevention, covers that:
  [git-recovery-checklist.md](git-recovery-checklist.md).
