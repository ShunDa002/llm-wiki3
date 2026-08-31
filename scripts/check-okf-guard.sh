#!/usr/bin/env bash
# Portable OKF semantic-immutability backstop (Phase 3, plan §3.6). Mirrors .githooks/pre-commit's
# raw/ pattern: Git runs this regardless of which agent produced the change, so it survives an
# agent switch the way an "ask" permission (Claude Code only) does not. Closes the gap named in
# docs/agent-portability.md ("protects raw/, not okf/") and docs/phase-2/status.md
# ("accepted-decision enforcement — Phase 3").
#
# Blocks:
#   1. Any modification, deletion, or rename of an okf/decisions/*.md file that is
#      `status: accepted` at the base commit — CLAUDE.md/AGENTS.md prohibit editing an accepted
#      decision outright, no exceptions.
#   2. Any modification, deletion, or rename of an okf/experiments/*.md file that is
#      `status: complete` at the base commit — its conclusion is final once recorded.
#   3. A change to an okf/projects/*.md file's `status`, `owner`, `started`, or `review_date`
#      frontmatter field. Appending a dated bullet to '## Status notes' is unaffected — only
#      these four fields are compared.
#
# KNOWN BLIND SPOT, same shape as the raw/ one that let commit f38689b land: this compares
# against HEAD, so a file that has never been committed has no baseline to compare against and is
# skipped. The live okf/ pages are currently untracked (only .gitkeep is committed), which makes
# this guard INERT against them until the pilot owner commits an okf/ baseline — exactly the fix
# 5c5ad09 was for raw/. Unlike raw/, there is no independent recorded hash to substitute (an
# accepted decision's status lives only in the file itself), so committing the baseline is the
# fix, not more script. See docs/phase-3/status.md#known-blind-spot.
#
# Usage: bash scripts/check-okf-guard.sh [--staged|--worktree]
#   --staged     compare the git index against HEAD (used by .githooks/pre-commit)
#   --worktree   compare the working tree against HEAD (default; used by verify-vault.sh)
# Exit: 0 no violation (or nothing to check yet), 1 violation found.
set -uo pipefail
cd "$(dirname "$0")/.."
. scripts/lib-vault.sh

mode="${1:---worktree}"
problems=0
report() { printf 'BLOCKED: %s\n' "$1"; problems=$((problems + 1)); }

if ! git rev-parse --verify -q HEAD >/dev/null; then
  echo "no commits yet — nothing to check"
  exit 0
fi

tmp_head=$(mktemp)
tmp_now=$(mktemp)
trap 'rm -f "$tmp_head" "$tmp_now"' EXIT

if [ "$mode" = "--staged" ]; then
  diff_status=$(git diff --cached --name-status --diff-filter=MDR HEAD -- okf || true)
else
  diff_status=$(git diff --name-status --diff-filter=MDR HEAD -- okf || true)
fi

while IFS=$'\t' read -r stat path rest; do
  [ -n "$path" ] || continue
  # Renames report as "R100  old  new" — the old path is what we look up against HEAD.
  case "$stat" in R*) : ;; esac
  git show "HEAD:$path" > "$tmp_head" 2>/dev/null || continue

  case "$path" in
    okf/decisions/*)
      if [ "$(frontmatter "$tmp_head" status)" = "accepted" ]; then
        report "$path — accepted decision changed ($stat). Editing an accepted decision is prohibited for the agent."
      fi
      ;;
    okf/experiments/*)
      if [ "$(frontmatter "$tmp_head" status)" = "complete" ]; then
        report "$path — completed experiment changed ($stat). Its recorded conclusion is not agent-editable once complete."
      fi
      ;;
    okf/projects/*)
      case "$stat" in
        M*) : ;;                # only a field-level diff makes sense for a modify
        *) report "$path — project file deleted or renamed ($stat)."; continue ;;
      esac
      if [ "$mode" = "--staged" ]; then
        git show ":$path" > "$tmp_now" 2>/dev/null || continue
      else
        cp "$path" "$tmp_now" 2>/dev/null || continue
      fi
      for field in status owner started review_date; do
        old=$(frontmatter "$tmp_head" "$field")
        new=$(frontmatter "$tmp_now" "$field")
        if [ "$old" != "$new" ]; then
          report "$path — protected field '$field' changed ('$old' -> '$new') without approval."
        fi
      done
      ;;
  esac
done <<< "$diff_status"

if [ "$problems" -eq 0 ]; then
  echo "No unauthorized OKF semantic changes."
  exit 0
fi
cat <<'EOF'

Per AGENTS.md/CLAUDE.md and docs/phase-3/okf-bridge.md, the agent may append evidence or propose
review but must not autonomously change an accepted decision, a completed experiment's conclusion,
or a project's status/owner/dates.

If this was an agent error:
  git restore --staged --worktree -- okf/

If the pilot owner genuinely intends this, bypass deliberately and on the record:
  git commit --no-verify
EOF
exit 1
