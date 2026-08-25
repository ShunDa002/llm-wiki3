#!/usr/bin/env bash
# Self-check for the agent-portability layer: the universal guard, the Git pre-commit backstop,
# and the policy-drift detector. Run: bash scripts/test-portability.sh
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/.." && pwd)

fail=0
ok()   { printf 'ok   %s\n' "$1"; }
bad()  { printf 'FAIL %s\n' "$1"; fail=1; }
G="$here/guard-raw-universal.sh"

# ---------------------------------------------------------------- guard: paths
expect_deny_path() {
  if bash "$G" --path "$1" >/dev/null 2>&1; then bad "path should DENY: $1"; else ok "deny path: $1"; fi
}
expect_allow_path() {
  if bash "$G" --path "$1" >/dev/null 2>&1; then ok "allow path: $1"; else bad "path should ALLOW: $1"; fi
}
expect_deny_path "raw/articles/x.md"
expect_deny_path "/abs/vault/raw/notes/y.md"
expect_allow_path "wiki/concepts/x.md"
expect_allow_path "okf/decisions/d.md"
expect_allow_path "rawdata/x.md"          # substring must not false-positive

# ------------------------------------------------------------- guard: commands
expect_deny_cmd() {
  if bash "$G" --command "$1" >/dev/null 2>&1; then bad "cmd should DENY: $1"; else ok "deny cmd: $1"; fi
}
expect_allow_cmd() {
  if bash "$G" --command "$1" >/dev/null 2>&1; then ok "allow cmd: $1"; else bad "cmd should ALLOW: $1"; fi
}
expect_deny_cmd 'echo hi > raw/articles/x.md'
expect_deny_cmd 'rm -rf raw/notes'
expect_deny_cmd 'sed -i s/a/b/ raw/x.md'
expect_deny_cmd 'mv raw/a.md raw/b.md'
expect_allow_cmd 'grep -r foo raw/ | head -5'
expect_allow_cmd 'cat raw/articles/x.md'
expect_allow_cmd 'rm /tmp/junk'

# Regression: the whole-command matcher used to deny these. A mutator in one segment plus an
# unrelated mention of the evidence dir in another segment is NOT a violation, and blocking it
# trained the operator to work around the guard — the worst possible outcome for a safety control.
expect_allow_cmd 'rm -rf /tmp/clone && grep -c . raw/articles/x.md'
expect_allow_cmd 'mkdir -p /tmp/out; wc -l raw/notes/a.md'

# ------------------------------------------------------------ guard: JSON mode
json_deny() { # <payload> <label>
  out=$(printf '%s' "$1" | bash "$G" --stdin-json --format json 2>/dev/null)
  case "$out" in
    *'"permissionDecision":"deny"'*) ok "json deny: $2" ;;
    *) bad "json should DENY: $2 (got: ${out:-<empty>})" ;;
  esac
}
json_allow() { # <payload> <label>
  out=$(printf '%s' "$1" | bash "$G" --stdin-json --format json 2>/dev/null)
  if [ -z "$out" ]; then ok "json allow: $2"; else bad "json should ALLOW: $2 (got: $out)"; fi
}
json_deny  '{"tool_name":"Write","tool_input":{"file_path":"raw/a.md"}}'            'Claude Write'
json_deny  '{"tool_name":"write_file","tool_input":{"file_path":"raw/a.md"}}'       'Gemini write_file'
json_deny  '{"tool_name":"apply_patch","tool_input":{"file_path":"raw/a.md"}}'      'Codex apply_patch'
json_deny  '{"tool_name":"run_shell_command","tool_input":{"command":"rm raw/a.md"}}' 'Gemini shell'
json_allow '{"tool_name":"Write","tool_input":{"file_path":"wiki/c.md"}}'           'Claude Write to wiki'
json_allow '{"tool_name":"Bash","tool_input":{"command":"grep x raw/a.md"}}'        'read-only shell'

# ------------------------------------------------- pre-commit hook, real git repo
tmp=$(mktemp -d)
trap 'rm -r -- "$tmp"' EXIT
(
  cd "$tmp" || exit 1
  git init -q .
  git config user.email t@t.t; git config user.name t
  mkdir -p .githooks "raw/articles" wiki
  cp "$root/.githooks/pre-commit" .githooks/pre-commit
  chmod +x .githooks/pre-commit
  git config core.hooksPath .githooks

  printf 'original evidence\n' > "raw/articles/a.md"
  printf 'page\n' > wiki/p.md
  git add -A && git commit -q -m init

  # Adding new evidence must be allowed.
  printf 'new evidence\n' > "raw/articles/b.md"
  git add -A
  if git commit -q -m "add evidence" 2>/dev/null; then
    echo "ok   pre-commit: allows ADDING evidence"
  else
    echo "FAIL pre-commit: blocked a legitimate evidence addition"; exit 3
  fi

  # Modifying tracked evidence must be blocked.
  printf 'tampered\n' >> "raw/articles/a.md"
  git add -A
  if git commit -q -m "tamper" 2>/dev/null; then
    echo "FAIL pre-commit: allowed MODIFICATION of tracked evidence"; exit 3
  else
    echo "ok   pre-commit: blocks modification of tracked evidence"
  fi
  git restore --staged --worktree -- raw/ 2>/dev/null || true

  # Deleting tracked evidence must be blocked.
  git rm -q "raw/articles/a.md"
  if git commit -q -m "delete" 2>/dev/null; then
    echo "FAIL pre-commit: allowed DELETION of tracked evidence"; exit 3
  else
    echo "ok   pre-commit: blocks deletion of tracked evidence"
  fi
  git reset -q --hard HEAD

  # Changes outside the evidence dir must pass.
  printf 'edit\n' >> wiki/p.md
  git add -A
  if git commit -q -m "wiki edit" 2>/dev/null; then
    echo "ok   pre-commit: allows normal wiki changes"
  else
    echo "FAIL pre-commit: blocked a normal wiki change"; exit 3
  fi
) || fail=1

# --------------------------------------------------- policy drift detection
# Real files must currently agree.
if bash "$here/check-policy-sync.sh" >/dev/null 2>&1; then
  ok "policy sync: live files agree"
else
  bad "policy sync: live AGENTS.md / CLAUDE.md disagree"
fi

# And the detector must actually fire on planted drift, or it is decoration.
d=$(mktemp -d)
mkdir -p "$d/scripts"
cp "$here/check-policy-sync.sh" "$d/scripts/"
cp "$root/AGENTS.md" "$d/AGENTS.md"
grep -v 'Never delete files' "$root/CLAUDE.md" > "$d/CLAUDE.md"
if (cd "$d" && bash scripts/check-policy-sync.sh >/dev/null 2>&1); then
  bad "policy sync: did NOT detect a removed invariant rule"
else
  ok "policy sync: detects a removed invariant rule"
fi
rm -r -- "$d"

echo
[ "$fail" -eq 0 ] && { echo PASS; exit 0; } || { echo FAILED; exit 1; }
