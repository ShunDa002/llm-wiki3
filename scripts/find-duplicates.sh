#!/usr/bin/env bash
# Phase 2 duplicate detection (implementation plan 2.5). Reports; merges nothing, ever.
#
#   bash scripts/find-duplicates.sh                    # scan the vault for existing collisions
#   bash scripts/find-duplicates.sh "Proposed Title"   # check a title BEFORE creating the page
#
# The seven checks from 2.5:
#   1 exact title            4 similar titles (same type only)
#   2 normalised filename    5 an existing page already states the proposed definition
#   3 frontmatter aliases    6 singular/plural      7 acronym vs expanded form
#
# Scope is wiki/ knowledge pages: concepts, syntheses, questions. Not wiki/sources/ — a source
# page is 1:1 with a raw file and its duplicate check is source_id, which ingest already does.
# Not okf/ — duplicate execution records are the owner's call, not a knowledge-hygiene finding.
#
# Exit: 0 nothing found, 1 possible duplicates reported.
set -uo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=lib-vault.sh
. scripts/lib-vault.sh

findings=0
report() { printf '%-18s %s\n' "$1" "$2"; findings=$((findings + 1)); }

# Every lookup key a page answers to: "<key>\t<file>\t<kind>".
# Keys are normalised, so check 1 (exact), 2 (filename) and 6 (plural) all collapse into one
# comparison rather than three passes.
key_table() {
  local f base title a ac
  while IFS= read -r f; do
    base=$(basename "$f" .md)
    printf '%s\t%s\ttitle\n' "$(printf '%s' "$base" | norm_title)" "$f"
    title=$(frontmatter "$f" title)
    if [ -n "$title" ] && [ "$title" != "$base" ]; then
      printf '%s\t%s\ttitle\n' "$(printf '%s' "$title" | norm_title)" "$f"
    fi
    while IFS= read -r a; do
      [ -n "$a" ] && printf '%s\t%s\talias\n' "$(printf '%s' "$a" | norm_title)" "$f"
    done < <(frontmatter_list "$f" aliases)
    ac=$(acronym_of "$base")
    [ -n "$ac" ] && printf '%s\t%s\tacronym\n' "$ac" "$f"
  done < <(wiki_pages)
}

table=$(key_table)

# Significant words of a title: 4+ characters, lowercased, plural collapsed, deduplicated.
title_words() { # <title-or-basename>
  printf '%s\n' "$1" | tr 'A-Z' 'a-z' | tr -cs 'a-z0-9' '\n' | awk 'length>3' | sed 's/s$//' | sort -u
}

# Check 4 is a RATIO, not a count. Two four-word titles sharing two words is ordinary vocabulary
# ("Wiki Index as Routing Layer" vs "Wiki Maintenance and Lint Layers" — not duplicates). Two
# three-word titles sharing two words is most of both titles. An absolute threshold flagged the
# first pair, and a check that cries wolf on correct structure is one people switch off.
OVERLAP_PCT=60
overlap_is_high() { # <words-a> <words-b>
  local a="$1" b="$2" na nb shared smaller
  na=$(grep -c . <<< "$a"); nb=$(grep -c . <<< "$b")
  [ "$na" -gt 0 ] && [ "$nb" -gt 0 ] || return 1
  shared=$(comm -12 <(printf '%s\n' "$a") <(printf '%s\n' "$b") | grep -c . || true)
  [ "$shared" -ge 2 ] || return 1
  smaller=$([ "$na" -lt "$nb" ] && echo "$na" || echo "$nb")
  [ $((shared * 100 / smaller)) -ge "$OVERLAP_PCT" ] || return 1
  printf '%s' "$shared"
}

echo "DUPLICATE DETECTION REPORT"
echo "Vault: $(pwd)"
echo

if [ "$#" -gt 0 ]; then
  # ---- candidate mode: is this proposed page already covered? ----
  candidate="$1"
  echo "Candidate: $candidate"
  echo
  ck=$(printf '%s' "$candidate" | norm_title)
  cac=$(acronym_of "$candidate")

  while IFS=$'\t' read -r key file kind; do
    [ -n "${key:-}" ] || continue
    if [ "$key" = "$ck" ]; then
      report "title-collision" "$file already answers to this title ($kind match)"
    elif [ -n "$cac" ] && [ "$key" = "$cac" ]; then
      report "acronym-collision" "$file matches the candidate's acronym '$cac' ($kind)"
    fi
  done <<< "$table"

  # Check 5: some existing page may already state this definition without owning the title.
  while IFS= read -r f; do
    grep -qiF "$candidate" "$f" && report "already-stated" "$f already mentions '$candidate' in its body"
  done < <(wiki_pages)

  # Check 4, against the candidate: significant-word overlap with an existing title.
  cwords=$(title_words "$candidate")
  while IFS= read -r f; do
    shared=$(overlap_is_high "$cwords" "$(title_words "$(basename "$f" .md)")") &&
      report "similar-title" "$f shares $shared significant words with the candidate"
  done < <(wiki_pages)
else
  # ---- vault mode: existing collisions ----
  # A key held by two different files is a duplicate unless every holder reached it by acronym —
  # two unrelated multi-word titles sharing initials is noise, and a noisy check gets ignored.
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    rows=$(awk -F'\t' -v k="$key" '$1==k' <<< "$table")
    files=$(cut -f2 <<< "$rows" | sort -u)
    [ "$(grep -c . <<< "$files")" -ge 2 ] || continue
    kinds=$(cut -f3 <<< "$rows" | sort -u | tr '\n' ',' | sed 's/,$//')
    [ "$kinds" = "acronym" ] && continue
    report "key-collision" "'$key' ($kinds) is claimed by: $(tr '\n' ' ' <<< "$files")"
  done < <(cut -f1 <<< "$table" | sort | uniq -d)

  # Check 4: significant-word overlap between two pages of the SAME type. Comparing across types
  # flags every concept against the synthesis written about it, which is correct structure, not a
  # duplicate.
  while IFS= read -r a; do
    while IFS= read -r b; do
      [ "$a" \< "$b" ] || continue
      [ "$(page_type "$a")" = "$(page_type "$b")" ] || continue
      shared=$(overlap_is_high "$(title_words "$(basename "$a" .md)")" \
                               "$(title_words "$(basename "$b" .md)")") &&
        report "similar-title" "$a <-> $b share $shared of their significant words (same type)"
    done < <(wiki_pages)
  done < <(wiki_pages)
fi

echo
if [ "$findings" -eq 0 ]; then
  echo "No possible duplicates found."
  exit 0
fi
echo "$findings possible duplicate(s). These are candidates for human judgement."
echo "Never auto-merge: two pages that look alike may be a concept and its counterclaim."
exit 1
