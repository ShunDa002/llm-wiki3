#!/usr/bin/env bash
# Phase 2 schema conformance. Checks every knowledge page's frontmatter against the minimum
# metadata schema in AGENTS.md / CLAUDE.md. Reports; repairs nothing.
#
# Four classes of finding:
#   missing-field        a required field is absent
#   unknown-field        a field nobody approved — this is how schemas rot
#   bad-value            a field outside its allowed set
#   bad-date             a date field that is not YYYY-MM-DD
#   type-folder-mismatch the declared type disagrees with the folder
#
# unknown-field is the one that matters most. Missing fields are visible when you read a page;
# quietly accumulating invented fields is not, and by the time anyone notices, the "minimum"
# schema has three dialects.
#
# templates/ is deliberately NOT scanned: its values are placeholders ("<YYYY-MM-DD>",
# "low | medium | high") that must fail these checks by design.
#
# Usage: bash scripts/check-schema.sh
# Exit:  0 no findings, 1 findings.
set -uo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=lib-vault.sh
. scripts/lib-vault.sh

findings=0
report() { printf '%-22s %s\n' "$1" "$2"; findings=$((findings + 1)); }

CLASSIFICATION='public internal confidential restricted'
CONFIDENCE='low medium high'
KNOWLEDGE_STATUS='current disputed superseded uncertain'
BOOL='true false'

# Top-level frontmatter keys actually present on a page.
keys_of() { awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} /^[A-Za-z_][A-Za-z0-9_]*:/{sub(":.*",""); print}' "$1"; }

in_list() { # <needle> <space-separated haystack>
  case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

check_enum() { # <file> <field> <allowed>
  local v; v=$(frontmatter "$1" "$2")
  [ -n "$v" ] || return 0
  in_list "$v" "$3" || report "bad-value" "$1: $2 = '$v' (allowed: $3)"
}

check_date() { # <file> <field>
  local v; v=$(frontmatter "$1" "$2")
  [ -n "$v" ] || return 0   # empty is allowed: a proposed decision has no decision_date yet
  [[ "$v" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || report "bad-date" "$1: $2 = '$v' (want YYYY-MM-DD)"
}

echo "SCHEMA CONFORMANCE REPORT"
echo "Vault: $(pwd)"
echo

while IFS= read -r f; do
  case "$f" in wiki/index.md|wiki/log.md|raw/*) continue ;; esac

  type=$(page_type "$f")
  if [ -z "$type" ]; then
    report "no-type" "$f has no 'type:' field — cannot be schema-checked"
    continue
  fi

  # Required and optional fields per type. Required = the minimum schema. Optional = approved
  # but not mandatory. Anything else is an unknown field.
  dates=''; opt=''
  case "$type" in
    concept)
      req='title type status classification tags sources created updated confidence knowledge_status'
      opt='aliases review_needed'
      dates='created updated'
      check_enum "$f" status 'draft active superseded' ;;
    synthesis)
      req='title type status classification tags sources based_on created updated confidence knowledge_status'
      opt='aliases review_needed'
      dates='created updated'
      check_enum "$f" status 'draft active superseded' ;;
    source)
      req='title type raw_file source_id source_kind author classification captured ingested status'
      dates='captured ingested'
      check_enum "$f" status 'pending processed failed'
      check_enum "$f" source_kind 'article notes transcript webpage research-note experiment-result'
      sid=$(frontmatter "$f" source_id)
      [[ "$sid" =~ ^[0-9a-f]{64}$ ]] ||
        report "bad-value" "$f: source_id is not a 64-hex sha256 ('$sid')" ;;
    question)
      req='title type status classification created updated'
      opt='tags sources answered_by'
      dates='created updated'
      check_enum "$f" status 'open answered abandoned' ;;
    project)
      req='title type status classification owner started review_date informed_by'
      dates='started review_date'
      check_enum "$f" status 'active paused done' ;;
    decision)
      req='title type status classification project decision_date review_date knowledge_basis validated_by'
      dates='decision_date review_date'
      check_enum "$f" status 'proposed accepted superseded rejected' ;;
    experiment)
      req='title type status classification project tests_decision started completed'
      dates='started completed'
      check_enum "$f" status 'planned running complete abandoned' ;;
    *)
      report "unknown-type" "$f declares type '$type', which the schema does not define"
      continue ;;
  esac

  # Folder and declared type must agree, or navigation and every folder-scoped script lie.
  want=$(case "$(dirname "$f")" in
    wiki/concepts) echo concept ;; wiki/syntheses) echo synthesis ;;
    wiki/sources) echo source ;;   wiki/questions) echo question ;;
    okf/projects) echo project ;;  okf/decisions) echo decision ;;
    okf/experiments) echo experiment ;; *) echo '' ;; esac)
  [ -n "$want" ] && [ "$want" != "$type" ] &&
    report "type-folder-mismatch" "$f is type '$type' but sits in $(dirname "$f")/ (expects '$want')"

  for k in $req; do
    has_field "$f" "$k" || report "missing-field" "$f: $k"
  done

  for k in $(keys_of "$f"); do
    in_list "$k" "$req $opt" || report "unknown-field" "$f: '$k' is not in the approved schema"
  done

  for k in $dates; do check_date "$f" "$k"; done
  check_enum "$f" classification "$CLASSIFICATION"
  check_enum "$f" confidence "$CONFIDENCE"
  check_enum "$f" knowledge_status "$KNOWLEDGE_STATUS"
  check_enum "$f" review_needed "$BOOL"
done < <(notes)

echo
if [ "$findings" -eq 0 ]; then
  echo "No findings. Every page matches the approved schema."
  exit 0
fi
echo "$findings finding(s). Schema drift is a defect, not a dialect — fix the page, or get the"
echo "schema change approved and update AGENTS.md, CLAUDE.md, and templates/ together."
exit 1
