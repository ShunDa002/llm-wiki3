#!/usr/bin/env bash
# Phase 1 structural lint. Reports findings with locations. Repairs nothing.
# Run: scripts/wiki-lint.sh
# Exit 0 = no findings, 1 = findings reported. Never a hard error on vault content.
set -uo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=lib-vault.sh
. scripts/lib-vault.sh

findings=0
report() { printf '%-28s %s\n' "$1" "$2"; findings=$((findings + 1)); }

graph=$(link_graph)
titles=$(existing_titles)

echo "WIKI LINT REPORT"
echo "Vault: $(pwd)"
echo "Commit: $(git rev-parse --short HEAD 2>/dev/null || echo none)"
echo

echo "-- broken links --"
while IFS=$'\t' read -r src tgt; do
  [ -z "${tgt:-}" ] && continue
  grep -qxF "$tgt" <<< "$titles" || report "broken-link" "$src -> [[$tgt]]"
done <<< "$graph"

echo
echo "-- missing source links --"
# Factual pages must say where their claims came from. Index, log and source pages are exempt.
while IFS= read -r f; do
  case "$f" in wiki/index.md|wiki/log.md|wiki/sources/*|raw/*|*/.gitkeep) continue ;; esac
  has_field "$f" sources || report "no-sources" "$f"
done < <(notes)

echo
echo "-- duplicate concepts --"
notes | sed 's#.*/##' | sort | uniq -d | while IFS= read -r d; do
  [ -n "$d" ] && report "duplicate-filename" "$d appears in: $(notes | grep -F "/$d" | tr '\n' ' ')"
done
# Case- and plural-insensitive near-duplicates, the ones a human eye slides past.
notes | sed 's#.*/##; s#\.md$##' | tr 'A-Z' 'a-z' | sed 's/s$//' | sort | uniq -d |
  while IFS= read -r n; do
    [ -n "$n" ] && report "near-duplicate" "normalised title '$n' matches more than one page"
  done

echo
echo "-- orphan pages --"
while IFS= read -r f; do
  case "$f" in wiki/index.md|wiki/log.md|raw/*) continue ;; esac
  base=$(basename "$f" .md)
  awk -F'\t' -v me="$f" -v b="$base" '$1 != me && $2 == b {found=1} END {exit !found}' <<< "$graph" ||
    report "orphan" "$f has no inbound link"
done < <(notes)

echo
echo "-- index omissions --"
# Syntheses are navigation-worthy by definition; concepts are a judgement call, so not flagged.
for f in wiki/syntheses/*.md; do
  [ -e "$f" ] || continue
  base=$(basename "$f" .md)
  grep -qF "[[$base" wiki/index.md 2>/dev/null || report "index-omission" "$base not in wiki/index.md"
done

echo
echo "-- missing log entries --"
for f in wiki/sources/*.md; do
  [ -e "$f" ] || continue
  base=$(basename "$f" .md)
  grep -qF "$base" wiki/log.md 2>/dev/null || report "no-log-entry" "$base never appears in wiki/log.md"
done

echo
echo "-- experiments without a conclusion --"
for f in okf/experiments/*.md; do
  [ -e "$f" ] || continue
  status=$(frontmatter "$f" status)
  if ! grep -qiE '^#+ *conclusion' "$f"; then
    report "no-conclusion" "$f (status: ${status:-unset})"
  elif [ "$status" = "complete" ] &&
       ! awk '/^#+ *[Cc]onclusion/{f=1;next} /^#+ /{f=0} f && NF' "$f" | grep -q .; then
    report "empty-conclusion" "$f is complete but the Conclusion section is empty"
  fi
done

echo
echo "-- decisions without a knowledge basis --"
for f in okf/decisions/*.md; do
  [ -e "$f" ] || continue
  has_field "$f" knowledge_basis || report "no-knowledge-basis" "$f"
done

echo
echo "-- unsupported synthesis claims --"
# A synthesis is a cross-source conclusion. One source means it is a summary wearing a hat.
for f in wiki/syntheses/*.md; do
  [ -e "$f" ] || continue
  n=$(awk '/^sources:/{f=1;next} f && /^[a-z_]+:/{exit} f && /^ *- /{c++} END{print c+0}' "$f")
  [ "$n" -lt 2 ] && report "single-source-synthesis" "$f cites $n source(s)"
done

echo
if [ "$findings" -eq 0 ]; then
  echo "No findings."
  exit 0
fi
echo "$findings finding(s). Recommendations only — lint does not repair semantic problems."
exit 1
