#!/usr/bin/env bash
# Read-only lock for raw/ evidence files — a native OS permission bit, not an agent hook.
#
# Why this exists: every guard in this vault so far (protect-raw.sh, guard-raw-universal.sh,
# .githooks/pre-commit) works by recognizing a *tool call* — a Write, an Edit, a shell command
# that looks like a mutation. An agent with no such hook (or one using a tool the text heuristic
# doesn't recognize) writes straight through. A missing write bit stops the write itself,
# regardless of which tool, IDE, or shell asked for it. This is what actually would have stopped
# the Antigravity probes that succeeded: replace_file_content on raw/articles/01, and a plain
# shell redirect into raw/probe6_var.md.
#
# This only protects existing files. It cannot stop someone from *creating* a new file in raw/
# (that needs the directory's own write bit, left alone here so the pilot owner can keep adding
# real evidence) — run this again after adding one to lock it down too.
#
# Usage: bash scripts/lock-raw.sh
#   To edit a locked file yourself first:  chmod u+w <file>
#   Then re-lock when done:                bash scripts/lock-raw.sh
set -euo pipefail
cd "$(dirname "$0")/.."

n=$(find raw -type f | wc -l)
find raw -type f -exec chmod a-w {} +
echo "Locked $n file(s) under raw/ read-only."
