#!/usr/bin/env bash
# Guards the one seam the pointer refactor couldn't eliminate: Claude Code's allowed-tools
# permission list is mechanism, not workflow content, so it still lives in
# .claude/commands/*.md rather than the canonical prompts/*.md. This checks two things a
# careless edit could silently break:
#
#   1. Each command file is still a thin pointer, not a re-forked copy of the workflow prose.
#   2. Every `bash scripts/*.sh` that prompts/<name>.md actually invokes is covered by an
#      allowed-tools Bash(...) entry in the matching .claude/commands/<name>.md.
#
# This is deliberately narrow — it does not diff prose content. The workflow content itself
# cannot drift anymore because there is only one copy of it (prompts/<name>.md); this only
# protects the thin adapter layer that necessarily still differs by agent.
#
# Usage: bash scripts/check-command-pointers.sh
# Exit:  0 in order, 1 a problem found, 2 a required file is missing.
set -uo pipefail
cd "$(dirname "$0")/.."

WORKFLOWS="wiki-ingest wiki-query wiki-lint"
problems=0
report() { printf 'PROBLEM: %s\n' "$1"; problems=$((problems + 1)); }

for name in $WORKFLOWS; do
  prompt="prompts/$name.md"
  cmd=".claude/commands/$name.md"

  for f in "$prompt" "$cmd"; do
    [ -f "$f" ] || { printf 'MISSING: %s\n' "$f" >&2; exit 2; }
  done

  # 1. The command file must point at the prompt, not re-state it.
  if ! grep -qE "Follow \`$prompt\`" "$cmd"; then
    report "$cmd does not point at $prompt — has it been re-forked into a full copy?"
  fi
  # A re-forked copy typically grows its own step/section structure. This is a heuristic, not
  # proof, but a pointer file has no legitimate reason to contain a "## Step" heading.
  if grep -qE '^## Step' "$cmd"; then
    report "$cmd contains its own '## Step' sections — looks like duplicated workflow content"
  fi

  # 2. Every script the prompt actually runs must be permitted in the command's allowed-tools.
  allowed=$(grep -m1 '^allowed-tools:' "$cmd" || true)
  while IFS= read -r script; do
    [ -z "$script" ] && continue
    if ! grep -qF "Bash(bash scripts/$script)" <<< "$allowed"; then
      report "$prompt invokes 'bash scripts/$script' but $cmd's allowed-tools does not permit it"
    fi
  done < <(grep -oE 'bash scripts/[A-Za-z0-9_.-]+\.sh' "$prompt" | sed 's#bash scripts/##' | sort -u)
done

if [ "$problems" -eq 0 ]; then
  echo "Command pointers are thin and their tool permissions cover what the workflows invoke."
  exit 0
fi
echo
echo "Fix the command file, not the prompt — the prompt is canonical."
exit 1
