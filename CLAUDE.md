# Vault operating policy — Claude Code entry point

@AGENTS.md

The line above imports `AGENTS.md`, the **single source of policy text** for this vault: the
`raw/`, `wiki/`, and `okf/` rules, the prohibited-operations list, the minimum metadata schema,
the approval model, the phase and automation level, and the per-agent enforcement table. This
file holds no rules of its own, by design.

It used to hold a second full copy, because `CLAUDE.md` could not be edited when the portability
layer was built. That constraint lapsed once Phase 2 and Phase 3 both edited it, so the
duplication was collapsed the same way `.claude/commands/*.md` became pointers at `prompts/` —
drift stops being *detected* and becomes *impossible*.

**Add a rule to `AGENTS.md`, never here.** `scripts/check-policy-sync.sh` fails if this file
re-grows policy text of its own, or if the import line goes missing.
