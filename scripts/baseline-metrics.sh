#!/usr/bin/env bash
# Phase 0 deliverable: the countable half of the baseline metrics.
# Read-only. Run from anywhere: scripts/baseline-metrics.sh
# Time-based metrics (time to find material, time to synthesize) are measured by hand;
# see docs/phase-0/baseline-metrics.md.
set -uo pipefail
cd "$(dirname "$0")/.."

# Vault markdown = wiki/ + okf/ + raw/. Excludes docs/, templates/, and the plan itself,
# which are process documents, not knowledge pages.
notes() { find wiki okf raw -type f -name '*.md' 2>/dev/null | sort; }

count() { grep -c . || true; }

total=$(notes | count)

# Notes with a body claim but no sources: field. Source pages and index/log are exempt.
no_sources=0
while IFS= read -r f; do
  case "$f" in */sources/*|*/index.md|*/log.md) continue ;; esac
  grep -qE '^sources:' "$f" || no_sources=$((no_sources + 1))
done < <(notes)

# Duplicate notes = same basename in more than one place.
dupes=$(notes | sed 's#.*/##' | sort | uniq -d | count)

# Link graph, built once: "<source file><TAB><link target basename>".
# Filenames contain spaces, so never pipe them through xargs.
links=$(notes | while IFS= read -r f; do
  grep -ho '\[\[[^]]*\]\]' "$f" 2>/dev/null |
    sed -e 's/^\[\[//' -e 's/\]\]$//' -e 's/|.*$//' -e 's/#.*$//' -e 's#.*/##' |
    while IFS= read -r t; do
      [ -n "$t" ] && printf '%s\t%s\n' "$f" "$t"
    done
done)

# Broken wikilinks: distinct targets with no matching .md basename in the vault.
existing=$(notes | sed 's#.*/##; s#\.md$##' | sort -u)
broken=0
while IFS= read -r t; do
  [ -z "$t" ] && continue
  grep -qxF "$t" <<< "$existing" || broken=$((broken + 1))
done <<< "$(cut -f2 <<< "$links" | sort -u)"

# Orphans: no *other* note links to them.
orphans=0
while IFS= read -r f; do
  case "$f" in */index.md|*/log.md) continue ;; esac
  base=$(basename "$f" .md)
  awk -F'\t' -v me="$f" -v b="$base" '$1 != me && $2 == b {found=1} END {exit !found}' <<< "$links" ||
    orphans=$((orphans + 1))
done < <(notes)

# OKF hygiene.
okf_files() { find okf -type f -path "*$1*" -name '*.md' 2>/dev/null; }

decisions=$(okf_files decision | count)
dec_no_basis=0
while IFS= read -r f; do
  grep -qE '^knowledge_basis:' "$f" || dec_no_basis=$((dec_no_basis + 1))
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
