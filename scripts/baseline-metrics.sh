#!/usr/bin/env bash
# Phase 0 deliverable: the countable half of the baseline metrics.
# Read-only. Run from anywhere: scripts/baseline-metrics.sh
# Counts trends over time. For findings with locations, use scripts/wiki-lint.sh.
# Time-based metrics are measured by hand; see docs/phase-0/baseline-metrics.md.
set -uo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=lib-vault.sh
. scripts/lib-vault.sh

total=$(notes | count)

# Wiki factual pages with a body claim but no sources: field. See wiki_pages() for scope —
# okf/ and raw/ legitimately don't use this field and were false-positiving here.
no_sources=0
while IFS= read -r f; do
  has_field "$f" sources || no_sources=$((no_sources + 1))
done < <(wiki_pages)

dupes=$(notes | sed 's#.*/##' | sort | uniq -d | count)

graph=$(link_graph)
titles=$(existing_titles)

broken=0
while IFS= read -r t; do
  [ -z "$t" ] && continue
  grep -qxF "$t" <<< "$titles" || broken=$((broken + 1))
done <<< "$(cut -f2 <<< "$graph" | sort -u)"

orphans=0
while IFS= read -r f; do
  case "$f" in */index.md|*/log.md) continue ;; esac
  base=$(basename "$f" .md)
  awk -F'\t' -v me="$f" -v b="$base" '$1 != me && $2 == b {found=1} END {exit !found}' <<< "$graph" ||
    orphans=$((orphans + 1))
done < <(notes)

okf_files() { find okf -type f -path "*$1*" -name '*.md' 2>/dev/null; }

decisions=$(okf_files decision | count)
dec_no_basis=0
while IFS= read -r f; do
  has_field "$f" knowledge_basis || dec_no_basis=$((dec_no_basis + 1))
done < <(okf_files decision)

experiments=$(okf_files experiment | count)
exp_concluded=0
while IFS= read -r f; do
  grep -qiE '^#+ *conclusion|^conclusion:' "$f" && exp_concluded=$((exp_concluded + 1))
done < <(okf_files experiment)

pct() { [ "$2" -eq 0 ] && echo "n/a (0 records)" || echo "$(( $1 * 100 / $2 ))%"; }

cat <<EOF
Vault: $(pwd)
Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'no commit yet')

Notes (wiki/ + okf/ + raw/)      : $total
Notes without a sources: field   : $no_sources
Duplicate note filenames         : $dupes
Broken internal wikilinks        : $broken
Orphan notes (no inbound link)   : $orphans
OKF decisions                    : $decisions
  without knowledge_basis        : $dec_no_basis
OKF experiments                  : $experiments
  with a documented conclusion   : $exp_concluded ($(pct "$exp_concluded" "$experiments"))
EOF
