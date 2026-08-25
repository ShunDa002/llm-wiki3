#!/usr/bin/env bash
# Agent-neutral raw/ write guard. Reusable core for any agent's pre-tool-call hook.
#
# The existing .claude/hooks/protect-raw.sh is untouched and still serves Claude Code. This
# script is the portable equivalent: same decision logic, but callable from any hook system,
# with a plain-text mode for agents that do not speak Claude's JSON hook protocol.
#
# Usage:
#   bash scripts/guard-raw-universal.sh --path <file>            # check a write target
#   bash scripts/guard-raw-universal.sh --command '<shell cmd>'  # check a shell command
#   <json>  | bash scripts/guard-raw-universal.sh --stdin-json   # Claude-style hook payload
#
#   --format text (default)  human-readable reason on stderr; exit 2 = deny, 0 = allow
#   --format json            Claude PreToolUse permissionDecision JSON on stdout; always exit 0
#
# Exit codes in text mode: 0 allow, 2 deny, 64 usage error.
set -uo pipefail

EVIDENCE_DIR="raw"
format=text
mode=""
value=""

while [ $# -gt 0 ]; do
  case "$1" in
    --path)        mode=path;   value="${2:-}"; shift 2 ;;
    --command)     mode=command; value="${2:-}"; shift 2 ;;
    --stdin-json)  mode=json;   shift ;;
    --format)      format="${2:-text}"; shift 2 ;;
    -h|--help)     sed -n '2,18p' "$0"; exit 0 ;;
    *) printf 'guard-raw-universal: unknown argument: %s\n' "$1" >&2; exit 64 ;;
  esac
done

[ -n "$mode" ] || { printf 'guard-raw-universal: need --path, --command, or --stdin-json\n' >&2; exit 64; }

# --- decision helpers -------------------------------------------------------

deny() {
  if [ "$format" = json ]; then
    if command -v jq >/dev/null 2>&1; then
      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
        "$(printf '%s' "$1" | jq -Rs .)"
    else
      # No jq: emit hand-escaped JSON rather than failing open. A guard that silently
      # allows because a dependency is missing is worse than no guard.
      esc=$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n' ' ')
      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$esc"
    fi
    exit 0
  fi
  printf 'DENY: %s\n' "$1" >&2
  exit 2
}

allow() { [ "$format" = json ] && exit 0; exit 0; }

path_hits_evidence() { # <path>
  case "$1" in
    "$EVIDENCE_DIR"/*|*/"$EVIDENCE_DIR"/*) return 0 ;;
    *) return 1 ;;
  esac
}

# A command is a violation only when the SAME shell segment both names the evidence directory
# and mutates something. Splitting on ; && || | matters: the whole-command version of this
# check produced false positives on innocuous compound commands where an unrelated `rm` in one
# segment sat beside a mere mention of raw/ in another.
command_hits_evidence() { # <command string>
  local cmd="$1" seg hits
  local mutators='\b(rm|mv|cp|tee|truncate|touch|mkdir|chmod|chown|dd|install|ln|shred|unlink|rmdir)\b'
  # Normalise segment separators to newlines, then test each segment independently.
  # Capture into a variable rather than piping to `grep -q`: grep -q exits on first match,
  # SIGPIPEs the upstream loop, and `set -o pipefail` then reports the pipeline as FAILED even
  # though the match succeeded — which silently turned every deny into an allow.
  # Trailing newline is required: without it `read` hits EOF holding the final segment and
  # returns non-zero, so a single-segment command (the common case) was never examined at all.
  hits=$(printf '%s\n' "$cmd" | tr ';|&' '\n\n\n' | while IFS= read -r seg; do
    [ -z "$seg" ] && continue
    # Boundary excludes word characters but NOT `/` or `.`, so an ordinary absolute or
    # variable-interpolated path — "$VAULT/raw/x", ./raw/x — is still caught. Excluding `/`
    # here (as the original Claude-only hook does) means any absolute path walks straight
    # through the guard, which is not obfuscation, just normal shell usage.
    printf '%s' "$seg" | grep -qE "(^|[^A-Za-z0-9_-])$EVIDENCE_DIR/" || continue
    if printf '%s' "$seg" | grep -qE ">>?[[:space:]]*[^[:space:]]*$EVIDENCE_DIR/" ||
       printf '%s' "$seg" | grep -qE "$mutators" ||
       printf '%s' "$seg" | grep -qE '(sed|perl)[[:space:]]+[^;]*-i'; then
      printf 'HIT\n'
    fi
  done)
  [ -n "$hits" ]
}

WRITE_MSG="Policy: $EVIDENCE_DIR/ is immutable evidence. Writes are prohibited for the agent. A human must add or change raw sources. See AGENTS.md."
CMD_MSG="Policy: $EVIDENCE_DIR/ is immutable evidence. This command appears to write, move, or delete under $EVIDENCE_DIR/. Read-only access only (cat, grep, find, head). See AGENTS.md."

# --- dispatch ---------------------------------------------------------------

case "$mode" in
  path)
    path_hits_evidence "$value" && deny "$WRITE_MSG"
    allow ;;
  command)
    command_hits_evidence "$value" && deny "$CMD_MSG"
    allow ;;
  json)
    payload=$(cat)
    if command -v jq >/dev/null 2>&1; then
      tool=$(printf '%s' "$payload" | jq -r '.tool_name // ""')
      p=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.notebook_path // ""')
      c=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
    else
      # Crude extraction, deliberately over-inclusive: without jq we would rather deny a
      # borderline call than let a raw/ write through unexamined.
      tool=$(printf '%s' "$payload" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
      p=$(printf '%s' "$payload" | sed -n 's/.*"\(file_path\|notebook_path\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\2/p')
      c=$(printf '%s' "$payload" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p')
    fi
    case "$tool" in
      Write|Edit|MultiEdit|NotebookEdit|write_file|edit_file|create_file|apply_patch|str_replace_editor)
        [ -n "$p" ] && path_hits_evidence "$p" && deny "$WRITE_MSG" ;;
      Bash|bash|shell|run_shell_command|run_terminal_cmd|execute_command)
        [ -n "$c" ] && command_hits_evidence "$c" && deny "$CMD_MSG" ;;
      *)
        # Unknown tool name from an agent we have not mapped: check both fields anyway.
        [ -n "$p" ] && path_hits_evidence "$p" && deny "$WRITE_MSG"
        [ -n "$c" ] && command_hits_evidence "$c" && deny "$CMD_MSG" ;;
    esac
    allow ;;
esac
