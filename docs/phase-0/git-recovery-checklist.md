# Phase 0 deliverable: Git recovery checklist

Date drilled: 2026-08-24
Baseline commit: `6dd65a3`, tagged `phase-0-baseline`
Result: all six procedures passed. Total drill time: **under 1 second** (exit criterion: a
deleted file restored in under five minutes).

Run this drill before granting the agent write access, and again quarterly.

## The six procedures

| # | Need | Command |
|---|---|---|
| 1 | See which files changed | `git status --short` |
| 2 | See line-level changes | `git diff` (one file: `git diff -- <path>`) |
| 3 | Restore one file | `git restore <path>` |
| 4 | Restore the whole working tree | `git restore .` |
| 5 | Recover an accidentally deleted file | `git restore <path>` |
| 6 | Compare with the last accepted state | `git diff --stat HEAD` or `git diff --stat phase-0-baseline` |

`git restore` discards uncommitted work in the target path. That is the point when undoing a bad
agent run, and a hazard if a human edit is mixed in — check `git diff` first (procedure 2).

## Recorded drill output

```text
Baseline: 6dd65a3 (tag phase-0-baseline)

### Test 1: view changed files
 M README.md
 M docs/phase-0/recovery-test.md

### Test 2: view line-level changes
@@ -3,3 +3,4 @@ title: Recovery Test
 Original line. Do not change.
+CORRUPTED by simulated agent error

### Test 3: restore one file
status after:  M README.md          <- only the untouched file remains dirty
content:       Original line. Do not change.

### Test 4: restore the full working tree
status after: (empty)

### Test 5: recover an accidentally deleted file
after delete:  D docs/phase-0/recovery-test.md
after restore: (empty)
file present: yes

### Test 6: compare current state with the last accepted state
vs HEAD:                     1 file changed, 1 insertion(+)
vs accepted baseline tag:     1 file changed, 6 insertions(+)
```

Test 3 is the one worth reading twice: restoring one file left the unrelated `README.md` change
alone. A recovery step that quietly reverts a human's concurrent edit is worse than the mistake
it fixes.

## Recovering from a bad agent run

```bash
git status --short                 # 1. what did it touch
git diff                           # 2. is any of it worth keeping
git restore .                      # 3a. discard everything uncommitted
git restore <path>                 # 3b. or just the damaged files
git diff --stat phase-0-baseline   # 4. confirm we are back at the accepted state
```

If the damage was already committed:

```bash
git log --oneline -10              # find the last good commit
git diff <good-sha> HEAD           # confirm what would be undone
git revert <bad-sha>               # preferred: keeps history auditable
```

Prefer `revert` over `reset --hard`. History is the audit trail; erasing it to hide a mistake
defeats the reason for versioning the vault.

## Accepting a good state

After reviewing a diff and approving it, the pilot owner commits. The agent never commits.

```bash
git add -A && git commit -m "<what changed and why>"
git tag -f last-accepted            # optional moving marker for procedure 6
```

## Quarterly re-drill

Re-run all six procedures and update the date at the top. A documented but untested recovery
procedure is an assumption, not a control.
