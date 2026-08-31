#!/usr/bin/env bash
# Phase 4 governance lint: the OKF layer and the cross-layer layer of plan §4.1, plus the two
# staleness checks the knowledge layer needs and nothing else was doing.
#
# Why a second script instead of more checks in wiki-lint.sh: wiki-lint.sh is a hard-fail gate
# (verify-vault.sh section 3, exit 1 blocks write work). Everything here is a *review prompt* —
# "this accepted decision rests on knowledge that changed since it was accepted" is a question for
# a human, not a broken vault. Mixing the two would either make review prompts block work, or
# demote real structural defects to advisory. Same reasoning that keeps the duplicate check
# advisory in verify-vault.sh section 7.
#
# Reports only. Never repairs, never writes, never touches okf/ — plan §4.2 puts every finding
# type here in the "propose" or "never automatic" column.
#
# Run: bash scripts/lint-governance.sh
# Exit: 0 no findings, 1 findings reported.
#
# Deferred OKF types (goals/, areas/, debriefs/, deliverables/, practices/) have no folder in this
# vault yet — see docs/phase-3/okf-bridge.md §3.1. The plan's findings for them ("goal without
# review date", "debrief without action items", "practice without supporting evidence") are
# deliberately not implemented: a check against a folder that does not exist can never fire, and
# writing it now would mean guessing that folder's schema. The review-date and knowledge-basis
# checks below are written against `okf/*/` generically, so a goal added later is covered by them
# without an edit.
set -uo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=lib-vault.sh
. scripts/lib-vault.sh

# Overridable so the self-check can pin dates instead of racing the calendar.
TODAY="${VAULT_TODAY:-$(date +%F)}"
STALE_DAYS="${VAULT_STALE_DAYS:-90}"

# ISO dates compare correctly as strings, which is the whole reason this script never parses one.
# The only arithmetic needed is "what was the date N days ago", and that is the one place GNU and
# BSD date disagree — hence both forms. An older instance of exactly this portability bug (an
# in-place `sed -i`) shipped in this repo already.
stale_cutoff() {
  date -d "$TODAY - $STALE_DAYS days" +%F 2>/dev/null ||
    date -j -v-"${STALE_DAYS}"d -f %Y-%m-%d "$TODAY" +%F 2>/dev/null ||
    echo "0000-00-00"   # cannot compute: never flag rather than flag everything
}
CUTOFF=$(stale_cutoff)

findings=0
report() { printf '%-30s %s\n' "$1" "$2"; findings=$((findings + 1)); }

# A scalar link field, reduced to the page title it names: strip quotes, [[ ]], any path prefix,
# an alias after |, and an anchor after #. frontmatter() returns the raw value, deliberately.
linkval() { # <file> <field>
  frontmatter "$1" "$2" |
    sed -e 's/^["'"'"']//' -e 's/["'"'"']$//' -e 's/^\[\[//' -e 's/\]\]$//' \
        -e 's/|.*$//' -e 's/#.*$//' -e 's#.*/##'
}

# Path of the page with this title, or empty. Titles are basenames in this vault by construction.
page_path() { # <title>
  [ -n "${1:-}" ] || return 0
  notes | grep -F "/$1.md" | head -1
}

kstatus() { # <title> -> knowledge_status of that page, or empty
  local p; p=$(page_path "$1"); [ -n "$p" ] && frontmatter "$p" knowledge_status
}

graph=$(link_graph)

echo "GOVERNANCE LINT REPORT (Phase 4: OKF and cross-layer)"
echo "Vault:  $(pwd)"
echo "Commit: $(git rev-parse --short HEAD 2>/dev/null || echo none)"
echo "Today:  $TODAY   stale after: $STALE_DAYS days (cutoff $CUTOFF)"
echo

# ============================ OKF LAYER ====================================
echo "-- OKF: knowledge basis and review dates --"
for f in okf/projects/*.md; do
  [ -e "$f" ] || continue
  # A project with no knowledge behind it is the "project without linked goal" finding in the form
  # this vault actually has: informed_by is what ties execution to compiled knowledge.
  [ -n "$(frontmatter_list "$f" informed_by)" ] || report "project-no-knowledge" "$f has no informed_by knowledge"
done

for f in okf/projects/*.md okf/decisions/*.md okf/goals/*.md; do
  [ -e "$f" ] || continue
  status=$(frontmatter "$f" status)
  case "$status" in active|accepted|proposed) ;; *) continue ;; esac
  rd=$(frontmatter "$f" review_date)
  if [ -z "$rd" ]; then
    report "okf-no-review-date" "$f (status: $status) has no review_date — nothing will ever re-open it"
  elif [ "$rd" \< "$TODAY" ]; then
    report "okf-review-overdue" "$f review_date $rd has passed (today $TODAY)"
  fi
done

echo
echo "-- OKF: experiment and decision linkage --"
for f in okf/experiments/*.md; do
  [ -e "$f" ] || continue
  d=$(linkval "$f" tests_decision)
  if [ -z "$d" ]; then
    report "experiment-no-decision" "$f tests no decision — its result has nowhere to land"
    continue
  fi
  # Reciprocity. Phase 3 documented the relationship in both directions but enforced neither, and
  # of the first two decision/experiment pairs this vault ever held, one was already asymmetric.
  # A one-way link means /bridge-impact walks the graph in one direction and silently misses work.
  dp=$(page_path "$d")
  if [ -z "$dp" ]; then
    report "link-not-reciprocal" "$f tests_decision [[$d]] — no such page"
  elif [ "$(linkval "$dp" validated_by)" != "$(basename "$f" .md)" ]; then
    report "link-not-reciprocal" "$f tests [[$d]], but that decision's validated_by is '$(linkval "$dp" validated_by)'"
  fi
done

for f in okf/decisions/*.md; do
  [ -e "$f" ] || continue
  v=$(linkval "$f" validated_by)
  [ -n "$v" ] || continue
  vp=$(page_path "$v")
  if [ -z "$vp" ]; then
    report "link-not-reciprocal" "$f validated_by [[$v]] — no such page"
  elif [ "$(linkval "$vp" tests_decision)" != "$(basename "$f" .md)" ]; then
    report "link-not-reciprocal" "$f is validated_by [[$v]], but that experiment's tests_decision is '$(linkval "$vp" tests_decision)'"
  fi
done

echo
echo "-- OKF: active work resting on disputed knowledge --"
# Plan §4.1: "Active project based on disputed knowledge." One hop through based_on as well as the
# direct citation, because a synthesis that resolves a contradiction for one scale is legitimately
# `current` while both concepts under it stay `disputed` — which is exactly this vault's shape, and
# exactly the thing a reviewer should see rather than have hidden by a one-level check.
for f in okf/projects/*.md; do
  [ -e "$f" ] || continue
  [ "$(frontmatter "$f" status)" = "active" ] || continue
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    t=$(sed -e 's#.*/##' -e 's/|.*$//' <<< "$t")
    case "$(kstatus "$t")" in
      disputed|uncertain) report "project-on-disputed-knowledge" "$f is informed_by [[$t]] ($(kstatus "$t"))" ;;
    esac
    p=$(page_path "$t"); [ -n "$p" ] || continue
    while IFS= read -r parent; do
      [ -n "$parent" ] || continue
      parent=$(sed -e 's#.*/##' -e 's/|.*$//' <<< "$parent")
      case "$(kstatus "$parent")" in
        disputed|uncertain)
          report "project-on-disputed-knowledge" "$f -> [[$t]] -> [[$parent]] is $(kstatus "$parent") (one hop via based_on)" ;;
      esac
    done < <(frontmatter_list "$p" based_on)
  done < <(frontmatter_list "$f" informed_by)
done

# ============================ CROSS-LAYER ==================================
echo
echo "-- cross-layer: decisions vs the knowledge under them --"
for f in okf/decisions/*.md; do
  [ -e "$f" ] || continue
  status=$(frontmatter "$f" status)
  ddate=$(frontmatter "$f" decision_date)
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    t=$(sed -e 's#.*/##' -e 's/|.*$//' <<< "$t")
    p=$(page_path "$t")
    if [ -z "$p" ]; then
      report "decision-basis-missing" "$f knowledge_basis [[$t]] — no such page"
      continue
    fi
    case "$(frontmatter "$p" knowledge_status)" in
      superseded) report "decision-cites-superseded" "$f rests on [[$t]], which is superseded" ;;
      disputed|uncertain) report "decision-cites-disputed" "$f rests on [[$t]] ($(frontmatter "$p" knowledge_status))" ;;
    esac
    # Plan §4.1: "Wiki update affects an accepted decision." This is /bridge-impact's job done
    # mechanically and in the other direction — /bridge-impact starts from a page the operator
    # already knows changed, which is no help for a change nobody remembered to follow up.
    upd=$(frontmatter "$p" updated)
    if [ "$status" = "accepted" ] && [ -n "$ddate" ] && [ -n "$upd" ] && [ "$ddate" \< "$upd" ]; then
      report "knowledge-changed-since-decision" "$f (accepted $ddate) rests on [[$t]], updated $upd — review, never auto-reopen"
    fi
  done < <(frontmatter_list "$f" knowledge_basis)
done

echo
echo "-- cross-layer: OKF citing evidence instead of knowledge --"
# Plan §4.1: "A project cites raw sources directly even though a synthesis exists." The Wiki is the
# compiled layer; an okf/ page reaching past it into raw/ or wiki/sources/ bypasses every scope,
# confidence, and contradiction record the knowledge layer holds.
#
# "even though a synthesis exists" is the load-bearing half of that sentence, and the first draft
# dropped it: flagging every evidence link outright fired on this vault's experiment page, which
# cites the source record OF ITSELF — provenance, not a bypass. So the finding requires both
# halves: it reaches into the evidence layer AND it cites no compiled page at all.
while IFS= read -r f; do
  ev=$(awk -F'\t' -v me="$f" '$1 == me {print $2}' <<< "$graph" | sort -u | while IFS= read -r t; do
        case "$(page_path "$t")" in raw/*|wiki/sources/*) printf '[[%s]] ' "$t" ;; esac
      done)
  [ -n "$ev" ] || continue
  compiled=$(awk -F'\t' -v me="$f" '$1 == me {print $2}' <<< "$graph" | while IFS= read -r t; do
        case "$(page_path "$t")" in wiki/concepts/*|wiki/syntheses/*) echo x ;; esac
      done)
  [ -n "$compiled" ] ||
    report "okf-cites-evidence-only" "$f cites evidence ($ev) and no compiled Wiki page"
done < <(find okf -type f -name '*.md' 2>/dev/null | sort)

echo
echo "-- cross-layer: superseded knowledge still in use --"
while IFS= read -r f; do
  [ "$(frontmatter "$f" knowledge_status)" = "superseded" ] || continue
  base=$(basename "$f" .md)
  inbound=$(awk -F'\t' -v me="$f" -v b="$base" '$1 != me && $2 == b {print $1}' <<< "$graph" | sort -u | tr '\n' ' ')
  [ -n "$inbound" ] && report "superseded-page-cited" "$f is superseded but still cited by: $inbound"
done < <(wiki_pages)

# ====================== KNOWLEDGE LAYER (staleness) ========================
echo
echo "-- knowledge: review staleness --"
# A claim block's "Last reviewed" is the only self-declared freshness date in the schema. Once it
# is older than the cadence, the block asserts rigour it no longer has.
while IFS= read -r f; do
  d=$(awk '/^#+ *Last reviewed/{f=1;next} f && NF {print $1; exit}' "$f")
  case "$d" in
    ????-??-??) [ "$d" \< "$CUTOFF" ] && report "claim-review-stale" "$f last reviewed $d (cutoff $CUTOFF)" ;;
    "") grep -qE '^#+ *Claim *$' "$f" && report "claim-review-undated" "$f has a claim block with no reviewable date" ;;
  esac
done < <(wiki_pages)

for f in wiki/questions/*.md; do
  [ -e "$f" ] || continue
  [ "$(frontmatter "$f" status)" = "open" ] || continue
  upd=$(frontmatter "$f" updated)
  [ -n "$upd" ] && [ "$upd" \< "$CUTOFF" ] &&
    report "question-stale" "$f open and untouched since $upd (cutoff $CUTOFF) — answer it or close it"
done

echo
if [ "$findings" -eq 0 ]; then
  echo "No findings."
  exit 0
fi
cat <<EOF
$findings finding(s). Every one is a review prompt, not a repair instruction: see
docs/phase-4/lint-layers.md for the fix policy per finding type. Nothing here may be auto-fixed,
and an accepted decision is never reopened by lint.
EOF
exit 1
