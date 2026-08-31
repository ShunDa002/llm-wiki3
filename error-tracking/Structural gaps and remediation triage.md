# Structural gaps and remediation triage

Date: 2026-08-31
Scope: the vault's folder structure and enforcement layer as of commit `9d82218`, after Phase 3
and five rounds of cross-agent (Antigravity / Gemini CLI) boundary testing.

This file records six shortcomings of the current structure and, for each, whether it is worth
fixing. It is deliberately not a test report: nothing here was found by running a test round.
These are structural properties of the design, found by reading it and by checking live repo state.

The triage is the point. Six findings with no ranking is a list; six findings sorted into *fix
now*, *leave alone*, and *cannot be fixed here* is a decision. Three are worth fixing, two should
be left alone, and one can only be fixed somewhere other than this repository.

---

## The six gaps

### 1. The `okf/` semantic guard was inert against live content — FIXED

**What was wrong.** `scripts/check-okf-guard.sh` compares each `okf/` file against its last
committed version. The real decision, experiment, and project pages had never been committed —
only empty `.gitkeep` placeholders were tracked. With no committed version there is nothing to
diff against, so the guard skipped them silently. Antigravity demonstrated this on purpose in the
Phase 3 round: it changed the accepted decision's status to `superseded`, and both the guard and
`verify-vault.sh` reported all clear.

**Why it mattered.** An agent without Claude Code's permission prompts could alter an accepted
decision with no automated check noticing. Human diff review before committing was the only
control. This is the same shape as the `raw/` blind spot that let tampered commit `f38689b` land
during boundary-test round 2.

**Status: fixed.** Commit `9d82218 Add okf/ guard baseline` tracks the three real OKF pages. The
guard now has a baseline and is live.

### 2. Two policy files state the same rules and can drift

`CLAUDE.md` and `AGENTS.md` both contain the full policy text — roughly 130 lines of rules stated
twice. `scripts/check-policy-sync.sh` checks that ~16 invariant rules and the phase number appear
in both, but it compares rule *presence*, not wording: it catches a rule that was deleted, not one
that was reworded into meaning something different.

The original reason for the duplication was a hard constraint — do not modify `CLAUDE.md`, so that
the working Claude Code setup could not break. **That constraint no longer holds.** `CLAUDE.md`
has been edited in both Phase 2 and Phase 3 (phase number, schema block, new workflow tables), so
the cost is now being paid for a rule that is no longer in force.

### 3. `allowed-tools` in `.claude/commands/*.md` is a residual duplication

Workflow content was single-sourced into `prompts/` and the command files became thin pointers.
One seam could not be collapsed: Claude Code's `allowed-tools` permission list is agent-specific
mechanism with no cross-agent equivalent to unify against, so it still lives in the command file
and can still fall out of step with the scripts its prompt actually invokes.

`scripts/check-command-pointers.sh` guards this narrowly — is the command file still a pointer,
and does `allowed-tools` cover every `bash scripts/*.sh` the prompt calls.

### 4. The OS-level `raw/` lock only covers files that already existed at its last run

`scripts/lock-raw.sh` applies `chmod 444` to files under `raw/`. It cannot lock a file that does
not exist yet, and file modes are not Git-tracked, so a new file stays writable until the script is
re-run and a fresh clone starts fully unlocked. `docs/agent-portability.md` states this, and adds
the part that makes it worse: `verify-vault.sh` does not check permissions, so a skipped
`lock-raw.sh` is **silent** until a write actually succeeds.

**This is live, not hypothetical.** As of this writing `raw/` holds 11 writable files:

| File | Tracked | Meaning |
|---|---|---|
| `raw/articles/probe-add-only.md` | yes | Committed at `987d9c1` and never re-locked. Committed evidence that is supposed to be frozen is writable. |
| `raw/notes/**` (10 files) | no | Newly added material, legitimately pending — the owner adds, then locks. |

The mode bit is representable on this filesystem (both `444` and `644` are present), so the gap is
real and detectable here, not an artifact of Windows permission emulation.

### 5. The page taxonomy and OKF object types are not filled out

Five `wiki/` page-type folders from plan §2.2 (`entities`, `architecture`, `operations`,
`applications`, `tools`) and six `okf/` object types from plan §3.1 (`goals`, `areas`, `debriefs`,
`deliverables`, `practices`, `dashboards`) do not exist. Each was deferred with a named creation
trigger rather than pre-built empty.

This is the "grow the schema only where an observed failure demands it" rule working as intended,
not an oversight. What it does mean is that the structure has only ever been exercised at very
small scale: seven sources, one synthesis, one project/decision/experiment triple.

### 6. An agent with no hooks and no shell reduces the vault to policy text

Every enforcement layer in this repository needs either a hook system or a shell: the Git
pre-commit hook, `verify-vault.sh`, `guard-raw-universal.sh`, `lock-raw.sh`. Under an agent that
has neither, all of them are unavailable and the vault is protected by `AGENTS.md`'s wording alone.
`AGENTS.md` says this plainly rather than implying safety that is not there.

---

## Triage

| # | Gap | Verdict |
|---|---|---|
| 1 | `okf/` guard inert | **Fixed** — one commit, `9d82218` |
| 2 | Two policy files drift | **Fix** — collapse into one source |
| 4 | `raw/` lock silently missed | **Fix** — make it loud in `verify-vault.sh` |
| 3 | `allowed-tools` duplication | **Leave alone** — every fix costs more than the risk |
| 5 | Taxonomy not filled out | **Leave alone** — not a defect; needs content, not code |
| 6 | No-hook, no-shell agent | **Cannot be fixed here** — only off-client enforcement helps |

### Worth fixing

**#1 — `okf/` guard inert (done).** One `git commit` turned a dead check live. No script was
written. A second source of truth was considered — recording each decision's accepted-status hash
in a separate manifest for the guard to compare against — and rejected: that manifest would need
manual synchronisation forever, while a commit solves the problem completely and permanently.
Highest value per unit of work of anything on this list, which is why it was done first.

**#2 — two policy files.** Worth fixing because the constraint that justified the duplication has
already lapsed, so the cost is now being paid for nothing. The fix is a pattern this repository has
already run successfully once: `.claude/commands/*.md` were collapsed into pointers at `prompts/`,
and the same move applies here — `CLAUDE.md` becomes a pointer/import and `AGENTS.md` becomes the
only copy. Drift stops being *detected* and starts being *impossible*, which is strictly better
than a checker.

It also removes work rather than adding it: `check-policy-sync.sh`'s original job disappears, and
the file gets repurposed into the much smaller job of confirming the pointer is still a pointer.
The one real risk is that Claude Code's `@path` import behaviour is unverified from inside this
vault, so the fix must gate on proving the import loads before any duplicated text is removed.

**#4 — silent `raw/` lock gap.** Worth fixing because it is cheap, it is currently firing on real
files, and the failure mode is silence. A control that has quietly stopped applying is worse than a
control known to be absent, because it is still trusted. Adding a permission check to
`verify-vault.sh` costs a few lines in a script that already runs everywhere, adds no new file, and
converts an invisible regression into a named finding.

The fix reports; it must not `chmod`. `verify-vault.sh` is a read-only verifier and a verifier that
repairs its own findings can no longer be trusted to report them. It should also distinguish
tracked from untracked files: a committed writable file is a regression and should fail, while a
newly added writable file is a normal pending state and should only be noted. Failing on the
normal case is how a check teaches its operator to switch it off — the same reasoning that made the
duplicate-candidate section of `verify-vault.sh` advisory rather than fatal.

### Not worth fixing

**#3 — `allowed-tools` duplication.** All three available fixes are worse than the current state:

- Grant a broad tool permission so the list never needs updating — weakens permission scoping,
  which is the only thing `allowed-tools` exists to provide.
- Generate the command files from `prompts/` with a script — introduces a build step and a class of
  generated files that must be regenerated in discipline, i.e. trades one drift risk for another.
- Keep syncing by hand — that is the current state.

The residual risk is small and already narrowly guarded by `check-command-pointers.sh`. This is a
seam that should be left visible and monitored rather than papered over.

**#5 — taxonomy not filled out.** There is nothing to fix in code. Creating the eleven deferred
folders now would pre-build empty structure ahead of any observed need, which is the exact failure
the deferral policy exists to prevent, and every one of them already carries a documented trigger
for when to create it. The real constraint behind this gap is sample size — seven sources — and the
remedy is source material, which only the pilot owner can add because the agent cannot write to
`raw/` by design. Writing code here would be motion, not progress.

### Cannot be fixed here

**#6 — no-hook, no-shell agent.** Nothing added to this repository can help, because the gap is
precisely the absence of the ability to run what this repository contains. The only real remedy is
to move enforcement off the client: a `pre-receive` hook on a remote, or a CI job that runs
`verify-vault.sh` on push. Server-side enforcement runs regardless of what the local agent can do,
which is the property none of the current layers have.

That fix is conditional on infrastructure that does not exist yet — the Phase 3 test round's
`git push` probe failed on a missing upstream branch, so there is no remote configured. If this
vault stays local, the ceiling stands and `AGENTS.md` documenting it honestly is the correct
response. If it is ever pushed anywhere, CI becomes the right place to fix this, not the vault.

---

## Related

- `docs/agent-portability.md` — enforcement layers, verified vs unverified, honest limitations
- `docs/session-summary.md` §8 — open items for the pilot owner
- `docs/phase-3/status.md` — Phase 3 exit criteria and the guard-baseline item this file's #1 closed
