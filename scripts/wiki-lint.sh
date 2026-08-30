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
# Wiki factual pages must say where their claims came from. okf/ cites via knowledge_basis or
# informed_by instead (checked separately below); raw/ is the evidence, not a citation of it.
while IFS= read -r f; do
  has_field "$f" sources || report "no-sources" "$f"
done < <(wiki_pages)

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
echo "-- recorded contradictions without disputed status --"
# Phase 2.6: a new source may confirm, qualify, supersede, or contradict. When a page records an
# actual contradiction, knowledge_status must say so — otherwise the disagreement is visible to a
# human reading the page but invisible to every query, filter, and impact report.
# A recorded contradiction always names both sides with wikilinks (ingest step D.3), so a
# Contradictions section with no wikilink is template boilerplate, not a finding. An explicit
# "None recorded." is also not a finding even when the paragraph goes on to link something else —
# a real vault page does exactly that, which is how this exemption earned its way in.
while IFS= read -r f; do
  body=$(awk '/^#+ *[Cc]ontradiction/{f=1;next} /^#+ /{f=0} f' "$f")
  grep -q '\[\[' <<< "$body" || continue
  grep -qi '^ *none recorded' <<< "$body" && continue
  [ "$(frontmatter "$f" knowledge_status)" = "disputed" ] ||
    report "contradiction-not-disputed" "$f records a contradiction but knowledge_status is '$(frontmatter "$f" knowledge_status)'"
done < <(wiki_pages)

echo
echo "-- incomplete claim blocks --"
# Phase 2.4: a structured claim block exists to make a high-value claim auditable. A block missing
# its scope or its review date is worse than prose — it looks rigorous without being it.
while IFS= read -r f; do
  grep -qE '^#+ *Claim *$' "$f" || continue
  for sub in Support Scope Confidence 'Last reviewed'; do
    grep -qE "^#+ *$sub" "$f" || report "claim-block-incomplete" "$f: claim block has no '$sub' section"
  done
done < <(wiki_pages)

echo
echo "-- wikilinks broken across a line --"
# A wikilink wrapped onto the next line renders in Obsidian but is invisible to every link-based
# check here, because the link graph is built line by line. The result is a link that looks present
# to a human and does not exist to lint: no broken-link finding, no inbound-link credit, no orphan
# detection. One such link was already live in this vault when this check was written.
while IFS=: read -r f n _; do
  [ -n "${f:-}" ] || continue
  report "wrapped-wikilink" "$f line $n — wikilink not closed on the same line"
done < <(notes | while IFS= read -r f; do grep -Hn '\[\[[^]]*$' "$f" 2>/dev/null; done)

echo
echo "-- index bloat --"
# Phase 2.7: the index is a routing layer, not a content replica. Two ways it stops routing:
# it grows toward one entry per page, or it links past the knowledge layer into raw evidence.
INDEX_LINK_CAP=25
if [ -f wiki/index.md ]; then
  n=$(grep -o '\[\[[^]]*\]\]' wiki/index.md | grep -c . || true)
  [ "$n" -gt "$INDEX_LINK_CAP" ] &&
    report "index-bloat" "wiki/index.md has $n links (cap $INDEX_LINK_CAP) — it is becoming a table of contents"
  # Process substitution, not a pipe: report() increments a counter, and a pipeline would run it
  # in a subshell where the increment is discarded.
  while IFS= read -r tgt; do
    [ -n "$tgt" ] || continue
    path=$(notes | grep -F "/$tgt.md" | head -1)
    case "$path" in
      wiki/sources/*) report "index-links-source" "wiki/index.md links [[$tgt]] — cite sources from concepts, not the index" ;;
      raw/*)          report "index-links-raw"    "wiki/index.md links [[$tgt]] in raw/ — the index routes to knowledge, not evidence" ;;
    esac
  done < <(awk -F'\t' '$1 == "wiki/index.md" {print $2}' <<< "$graph" | sort -u)
fi

echo
if [ "$findings" -eq 0 ]; then
  echo "No findings."
  exit 0
fi
echo "$findings finding(s). Recommendations only — lint does not repair semantic problems."
exit 1
