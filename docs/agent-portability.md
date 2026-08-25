# Agent portability

How this vault stays workable when the AI agent changes. Added without modifying any existing
file, so the working Claude Code setup is untouched.

## The core idea

**Policy is portable. Enforcement is not.**

Rules can live in a Markdown file every agent reads. Enforcement cannot: each agent has its own
permission model and hook system, and several have none at all. Before this change, `raw/`
immutability rested entirely on a Claude Code `PreToolUse` hook — switch to Codex or Gemini and
that control silently disappeared while the policy document still claimed it existed.

The fix is a backstop that no agent can bypass because no agent is running it: a **Git pre-commit
hook**. Git runs it regardless of which agent, editor, or human produced the change.

```
Layer                                  Protects against          Works under
─────────────────────────────────────────────────────────────────────────────────────
.githooks/pre-commit                   committing raw/ changes   ANY agent · ANY editor · humans
scripts/verify-vault.sh                drift, tampering, rot     any agent that runs a shell
scripts/guard-raw-universal.sh         the write, pre-commit     any agent with a pre-tool hook
.claude/settings.json permissions.deny the write, pre-commit     Claude Code only
.claude/hooks/protect-raw.sh           the write, pre-commit     Claude Code only
AGENTS.md and friends                  nothing — it informs      every agent that reads it
```

Only the top two rows survive an agent switch. Everything below is a fast-feedback bonus.

## One-time setup, per clone

```bash
git config core.hooksPath .githooks
bash scripts/verify-vault.sh
```

`core.hooksPath` is local config, not a tracked file, so **every clone must do this** — including
yours after a re-clone. `verify-vault.sh` fails loudly when it is not armed, which is the point.

The hook is committed with mode `100755` (forced via `git update-index --chmod=+x`) because this
filesystem reports `core.fileMode=false`. Without that, a fresh clone would materialise the hook
non-executable and Git would skip it in silence.

## Entry-point files by agent

Each agent looks for its own filename. All of them are pointers to `AGENTS.md`; only `AGENTS.md`
and `CLAUDE.md` contain policy text.

| Agent | File | Status |
|---|---|---|
| Claude Code | `CLAUDE.md` | **Pre-existing, unmodified.** Still the live setup. |
| Codex CLI, and most agents following the convention | `AGENTS.md` | Added. Canonical policy. |
| Gemini CLI | `GEMINI.md` | Added, pointer. |
| GitHub Copilot | `.github/copilot-instructions.md` | Added, pointer. |
| Cursor | `.cursor/rules/vault-policy.mdc` | Added, pointer. **Frontmatter format unverified** — see below. |
| Anything else | `AGENTS.md` | Point the agent at it manually. |

### Verified vs. unverified

Verified by running it here:

- The pre-commit hook blocks modification and deletion of tracked evidence, allows additions, and
  allows normal `wiki/` changes — `scripts/test-portability.sh`, in a real throwaway Git repo.
- `guard-raw-universal.sh` denies and allows correctly across path, command, and JSON modes,
  including tool names used by Claude, Codex, and Gemini.
- `check-policy-sync.sh` detects a removed invariant rule.
- Committed hook mode is `100755` and survives a clone.

Not verified, because it cannot be tested from inside this vault:

- Whether Codex, Gemini, Copilot, or Cursor actually *loads* its entry-point file in your
  installed version. Filenames and formats change between releases. `.cursor/rules/*.mdc`
  frontmatter in particular has shifted across Cursor versions.
- Per-agent custom-command mechanisms (Gemini's TOML commands, Codex project prompts). These were
  deliberately **not** written, rather than guessed at and shipped broken. The `prompts/*.md`
  files work with any agent by simply being read — no config format required.

If an entry-point file turns out to be ignored by your agent, the fallback always works: tell the
agent "read AGENTS.md and follow it" at the start of the session.

## Workflows without slash commands

`/wiki-ingest`, `/wiki-query`, and `/wiki-lint` are Claude Code slash commands. The same workflows
live agent-neutrally in `prompts/`:

| Workflow | Portable definition | Claude Code equivalent |
|---|---|---|
| Ingest | `prompts/wiki-ingest.md` | `/wiki-ingest` |
| Query | `prompts/wiki-query.md` | `/wiki-query` |
| Lint | `prompts/wiki-lint.md` | `/wiki-lint` |

Under another agent: *"Follow prompts/wiki-ingest.md for raw/articles/01-example.md."* The
`.claude/commands/` files are untouched and remain authoritative for Claude Code.

The two sets are near-identical today. If you edit one, edit the other — there is no automated
sync check for the prompts, only for the policy files. See the honesty note below.

## Wiring a pre-tool guard for a new agent

If your agent supports a pre-tool-call hook, get per-write protection instead of waiting for
commit time. `guard-raw-universal.sh` is built for this:

```bash
# Path check — exit 2 means deny
bash scripts/guard-raw-universal.sh --path "wiki/concepts/x.md"

# Shell command check
bash scripts/guard-raw-universal.sh --command 'rm -rf raw/notes'

# Claude-style JSON payload on stdin, JSON decision on stdout
echo "$PAYLOAD" | bash scripts/guard-raw-universal.sh --stdin-json --format json
```

It recognises tool names from Claude (`Write`, `Edit`, `Bash`, …), Codex (`apply_patch`), and
Gemini (`write_file`, `run_shell_command`), and falls back to checking both a path and a command
field for tool names it does not know.

Its command check is a **text heuristic** and can be evaded by obfuscation — a base64'd path, a
variable holding the directory name, a script written elsewhere then executed. It is a speed bump,
not a sandbox. The pre-commit hook and `git diff` review are what actually hold.

It matches per shell segment (splitting on `;`, `|`, `&`) rather than across the whole command.
The whole-command version produced false positives on compound commands where an unrelated `rm`
in one segment sat beside a mere mention of `raw/` in another. That mattered: a guard that blocks
legitimate work teaches the operator to route around it, which is worse than no guard.

## Honest limitations

1. **Two policy files can drift.** `CLAUDE.md` could not become a pointer to `AGENTS.md` without
   editing it, and the instruction was to leave it alone. So the same rules exist twice.
   `scripts/check-policy-sync.sh` checks that ~16 invariant rules and the phase number appear in
   both, and `verify-vault.sh` runs it. It compares rules, not prose — wording may differ freely.
   It will not catch a *changed* rule that keeps its keyword.
2. **The `prompts/` and `.claude/commands/` duplication has no sync check.** Same cause,
   accepted deliberately; a checker for prose workflows would be more false positives than value.
   Edit both.
3. **The pre-commit hook is bypassable** with `git commit --no-verify`, on purpose: the pilot
   owner legitimately needs to correct a mis-captured source. It is a control against agent
   error, not a control against a determined human.
4. **It protects `raw/`, not `okf/`.** Accepted-decision immutability is still policy-only. A
   hook could enforce it, but the plan puts semantic OKF protection in Phase 3 and inventing it
   now would be guessing at rules that phase hasn't defined.
5. **Nothing here protects against an agent with no hooks and no shell.** In that mode the vault
   is policy-only, which `AGENTS.md` says plainly rather than implying safety that isn't there.

## Files added

```
AGENTS.md                          canonical, agent-neutral policy
GEMINI.md                          Gemini entry point (pointer)
.github/copilot-instructions.md    Copilot entry point (pointer)
.cursor/rules/vault-policy.mdc     Cursor entry point (pointer)
.githooks/pre-commit               portable enforcement backstop
prompts/wiki-{ingest,query,lint}.md   agent-neutral workflows
scripts/guard-raw-universal.sh     reusable pre-tool guard core
scripts/verify-vault.sh            agent-independent verification
scripts/check-policy-sync.sh       policy-drift detector
scripts/test-portability.sh        self-check for all of the above
docs/agent-portability.md          this file
```

Nothing existing was modified. Verify with `git status` — every path above is new.
