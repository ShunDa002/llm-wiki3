#!/usr/bin/env bash
# Phase 0 control: raw/ is immutable evidence. Deny any agent write to it.
# PreToolUse hook. Input: hook JSON on stdin. Output: permissionDecision JSON.
set -uo pipefail

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$(printf '%s' "$1" | jq -Rs .)"
  exit 0
}

payload=$(cat)
tool=$(printf '%s' "$payload" | jq -r '.tool_name // ""')

case "$tool" in
  Write|Edit|MultiEdit|NotebookEdit)
    path=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.notebook_path // ""')
    case "$path" in
      */raw/*|raw/*)
        deny "Phase 0 policy: raw/ is immutable evidence. Writes to raw/ are prohibited for the agent. A human must add or change raw sources." ;;
    esac
    ;;
  Bash)
    cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
    # Only care when the command both names raw/ and looks like a mutation.
    if printf '%s' "$cmd" | grep -qE '(^|[^A-Za-z0-9_./-])raw/' &&
       printf '%s' "$cmd" | grep -qE '(>>?[[:space:]]*[^|&]*raw/|\b(rm|mv|cp|tee|truncate|touch|mkdir|chmod|chown|dd|install|ln|shred|unlink|rmdir)\b|sed[[:space:]]+[^|;]*-i|perl[[:space:]]+[^|;]*-i)'; then
      deny "Phase 0 policy: raw/ is immutable evidence. This command appears to write, move, or delete under raw/. Read-only access only (cat, grep, find, head)."
    fi
    ;;
esac
exit 0
