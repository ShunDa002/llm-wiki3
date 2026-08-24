#!/usr/bin/env bash
# Shared read-only vault helpers. Sourced by baseline-metrics.sh and wiki-lint.sh.
# Assumes the caller has already cd'd to the vault root.

# Knowledge pages. Excludes docs/, templates/, scripts/ — process documents, not knowledge.
notes() { find wiki okf raw -type f -name '*.md' 2>/dev/null | sort; }

# Wiki factual pages only, excluding wiki/sources/ (provenance IS the page), index, and log.
# Use this for the "every factual page cites sources" check — okf/ pages cite via
# knowledge_basis/informed_by instead, and raw/ files are the evidence, not a citation of it.
# Scanning all of wiki+okf+raw for a `sources:` field flagged 10 false positives once already.
wiki_pages() {
  notes | grep '^wiki/' | grep -v '^wiki/sources/' | grep -vE '^wiki/(index|log)\.md$'
}

count() { grep -c . || true; }

# Every wikilink as "<source file><TAB><target basename>".
# Filenames contain spaces, so never pipe them through xargs — that bug shipped once already.
link_graph() {
  notes | while IFS= read -r f; do
    grep -ho '\[\[[^]]*\]\]' "$f" 2>/dev/null |
      sed -e 's/^\[\[//' -e 's/\]\]$//' -e 's/|.*$//' -e 's/#.*$//' -e 's#.*/##' |
      while IFS= read -r t; do
        [ -n "$t" ] && printf '%s\t%s\n' "$f" "$t"
      done
  done
}

# Page titles that exist, as basenames without .md.
existing_titles() { notes | sed 's#.*/##; s#\.md$##' | sort -u; }

# Frontmatter field value, or empty. Reads only the leading --- block.
frontmatter() { # <file> <field>
  awk -v k="$2" '
    NR==1 && $0!="---" {exit}
    NR>1 && $0=="---" {exit}
    $0 ~ "^"k":" {sub("^"k":[ \t]*",""); print; exit}
  ' "$1"
}

# True when the frontmatter has the field at all, list-valued included.
has_field() { grep -qE "^$2:" "$1"; }
