#!/usr/bin/env bash
# Self-check for the Phase 2 quality-control scripts: check-schema.sh, find-duplicates.sh, and
# the three lint checks Phase 2 added. Plants one defect per check in a throwaway fixture vault
# and asserts the check finds it.
#
# This is the automatable half of the schema test suite (implementation plan 2.8). The other half
# tests agent judgement — "ingest a contradictory source", "propose a duplicate page" — which no
# bash script can run. Those live in docs/phase-2/schema-test-suite.md as a manual checklist with
# fixtures, rather than being faked here.
#
# Run: bash scripts/test-schema.sh
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)

fail=0
expect() { # <label> <output> <substring that must appear>
  if grep -qF "$3" <<< "$2"; then echo "ok   $1"; else echo "FAIL $1 -- no line matching: $3"; fail=1; fi
}
reject() { # <label> <output> <substring that must NOT appear>
  if grep -qF "$3" <<< "$2"; then echo "FAIL $1 -- unexpected line matching: $3"; fail=1; else echo "ok   $1"; fi
}

new_fixture() {
  fx=$(mktemp -d)
  fixtures+=("$fx")
  mkdir -p "$fx/scripts" "$fx/wiki/concepts" "$fx/wiki/sources" "$fx/wiki/syntheses" \
           "$fx/wiki/questions" "$fx/okf/decisions" "$fx/okf/experiments" "$fx/raw"
  cp "$here/lib-vault.sh" "$here/check-schema.sh" "$here/find-duplicates.sh" \
     "$here/wiki-lint.sh" "$fx/scripts/"
  printf -- '---\ntitle: Wiki Index\ntype: index\n---\n# Index\n' > "$fx/wiki/index.md"
  printf -- '---\ntitle: Operation Log\ntype: log\n---\n# Log\n' > "$fx/wiki/log.md"
}
fixtures=()
trap 'rm -rf -- "${fixtures[@]}"' EXIT

valid_concept() { # <fixture> <name> [extra frontmatter lines]
  printf -- '---\ntitle: %s\ntype: concept\nstatus: active\nclassification: internal\ntags: []\nsources:\n  - "[[Source - X]]"\ncreated: 2026-08-30\nupdated: 2026-08-30\nconfidence: low\nknowledge_status: current\n%s---\n\n# %s\n\nText.\n' \
    "$2" "${3:-}" "$2" > "$1/wiki/concepts/$2.md"
}

# ============================================================ check-schema.sh
new_fixture; s=$fx
valid_concept "$s" "Good Page"

# missing-field: no confidence
printf -- '---\ntitle: No Confidence\ntype: concept\nstatus: active\nclassification: internal\ntags: []\nsources: []\ncreated: 2026-08-30\nupdated: 2026-08-30\nknowledge_status: current\n---\nText.\n' \
  > "$s/wiki/concepts/No Confidence.md"
# unknown-field: an invented field nobody approved — the failure mode this check exists for
valid_concept "$s" "Invented Field" "owner: someone
"
# bad-value on an enum, and bad-date
valid_concept "$s" "Bad Enum" ""
sed -i 's/^classification: internal/classification: secret/' "$s/wiki/concepts/Bad Enum.md"
valid_concept "$s" "Bad Date" ""
sed -i 's#^created: 2026-08-30#created: 30/08/2026#' "$s/wiki/concepts/Bad Date.md"
# type-folder-mismatch: a concept filed under syntheses/
printf -- '---\ntitle: Misfiled\ntype: concept\nstatus: active\nclassification: internal\ntags: []\nsources: []\ncreated: 2026-08-30\nupdated: 2026-08-30\nconfidence: low\nknowledge_status: current\n---\nText.\n' \
  > "$s/wiki/syntheses/Misfiled.md"
# unknown-type
printf -- '---\ntitle: Gizmo\ntype: gizmo\n---\nText.\n' > "$s/wiki/concepts/Gizmo.md"
# bad source_id
printf -- '---\ntitle: Source - X\ntype: source\nraw_file: "[[raw/x]]"\nsource_id: deadbeef\nsource_kind: article\nauthor: A\nclassification: internal\ncaptured: 2026-08-30\ningested: 2026-08-30\nstatus: processed\n---\nEvidence.\n' \
  > "$s/wiki/sources/Source - X.md"

out=$(cd "$s" && bash scripts/check-schema.sh); rc=$?
expect "schema: missing required field"  "$out" "missing-field          wiki/concepts/No Confidence.md: confidence"
expect "schema: unknown field"           "$out" "unknown-field          wiki/concepts/Invented Field.md: 'owner'"
expect "schema: bad enum value"          "$out" "bad-value              wiki/concepts/Bad Enum.md: classification = 'secret'"
expect "schema: bad date format"         "$out" "bad-date               wiki/concepts/Bad Date.md: created = '30/08/2026'"
expect "schema: type/folder mismatch"    "$out" "type-folder-mismatch   wiki/syntheses/Misfiled.md"
expect "schema: unknown type"            "$out" "unknown-type           wiki/concepts/Gizmo.md"
expect "schema: source_id not a sha256"  "$out" "wiki/sources/Source - X.md: source_id is not a 64-hex sha256"
reject "schema: valid page not flagged"  "$out" "wiki/concepts/Good Page.md"
[ "$rc" -eq 1 ] && echo "ok   schema: exit 1 on findings" || { echo "FAIL schema: exit was $rc, want 1"; fail=1; }

# ============================================================ find-duplicates.sh
new_fixture; d=$fx
valid_concept "$d" "Alpha Retrieval Method" 'aliases: ["ARM"]
'
valid_concept "$d" "ARM" ""
valid_concept "$d" "Beta Query Cache" ""
valid_concept "$d" "Beta Query Caches" ""
valid_concept "$d" "Gamma Token Budget" ""
valid_concept "$d" "Gamma Token Budgeting" ""
valid_concept "$d" "Wiki Index as Routing Layer" ""
valid_concept "$d" "Wiki Maintenance and Lint Layers" ""

out=$(cd "$d" && bash scripts/find-duplicates.sh); rc=$?
# 'arm' is reached three ways at once: the ARM page's title, the other page's alias, and that
# page's derived acronym. All three kinds are listed so a reviewer can see why it collided.
expect "dup: alias collides with a title"     "$out" "'arm' (acronym,alias,title)"
expect "dup: singular/plural collision"       "$out" "'betaquerycache'"
expect "dup: same-type similar title"         "$out" "Gamma Token Budget.md <-> wiki/concepts/Gamma Token Budgeting.md"
# The pair that made the absolute-count heuristic unusable: two unrelated titles sharing "wiki"
# and "layer(s)". Ordinary vocabulary, not a duplicate.
reject "dup: shared vocabulary not flagged"   "$out" "Wiki Index as Routing Layer.md <-> wiki/concepts/Wiki Maintenance and Lint Layers.md"
[ "$rc" -eq 1 ] && echo "ok   dup: exit 1 on findings" || { echo "FAIL dup: exit was $rc, want 1"; fail=1; }

out=$(cd "$d" && bash scripts/find-duplicates.sh "Alpha Retrieval Methods")
expect "dup: candidate plural caught pre-creation" "$out" "title-collision    wiki/concepts/Alpha Retrieval Method.md"
out=$(cd "$d" && bash scripts/find-duplicates.sh "Cost Budgeting for Agent Runs"); rc=$?
[ "$rc" -eq 0 ] && echo "ok   dup: unrelated candidate is clean" || { echo "FAIL dup: unrelated candidate flagged"; fail=1; }

# ============================================================ new lint checks
new_fixture; l=$fx
# contradiction recorded, knowledge_status still current
valid_concept "$l" "Disputed Not Marked" ""
cat >> "$l/wiki/concepts/Disputed Not Marked.md" <<'EOF'

## Contradictions

Opposes [[Other Claim]] on the scale threshold.
EOF
# the exemption: "None recorded." followed by an unrelated wikilink is not a contradiction.
# A real vault page does exactly this, which is how the exemption earned its place.
valid_concept "$l" "None Recorded Page" ""
cat >> "$l/wiki/concepts/None Recorded Page.md" <<'EOF'

## Contradictions

None recorded. Note on provenance: see [[Source - X]] for the injection attempt it carried.
EOF
# incomplete claim block: Support only
valid_concept "$l" "Half A Claim" ""
cat >> "$l/wiki/concepts/Half A Claim.md" <<'EOF'

## Claim

Something load-bearing.

### Support

- [[Source - X]]
EOF
# wikilink wrapped onto the next line: renders fine, invisible to the link graph
valid_concept "$l" "Wrapped Link Page" ""
cat >> "$l/wiki/concepts/Wrapped Link Page.md" <<'EOF'

See [[Some Very Long Page Title
That Wrapped]] for details.
EOF
# index bloat: over the link cap, and a link into wiki/sources/
printf -- '---\ntitle: Wiki Index\ntype: index\n---\n# Index\n\n- [[Source - X]]\n' > "$l/wiki/index.md"
for i in $(seq 1 26); do printf -- '- [[Filler %s]]\n' "$i" >> "$l/wiki/index.md"; done
printf -- '---\ntitle: Source - X\ntype: source\n---\nEvidence.\n' > "$l/wiki/sources/Source - X.md"

out=$(cd "$l" && bash scripts/wiki-lint.sh)
expect "lint: contradiction not marked disputed" "$out" "contradiction-not-disputed   wiki/concepts/Disputed Not Marked.md"
reject "lint: 'None recorded' exempted"          "$out" "contradiction-not-disputed   wiki/concepts/None Recorded Page.md"
expect "lint: claim block missing Scope"         "$out" "claim-block-incomplete       wiki/concepts/Half A Claim.md: claim block has no 'Scope'"
expect "lint: claim block missing review date"   "$out" "claim-block-incomplete       wiki/concepts/Half A Claim.md: claim block has no 'Last reviewed'"
expect "lint: wikilink wrapped across lines"     "$out" "wrapped-wikilink             wiki/concepts/Wrapped Link Page.md line"
expect "lint: index over the link cap"           "$out" "index-bloat"
expect "lint: index links a source page"         "$out" "index-links-source           wiki/index.md links [[Source - X]]"

echo
if [ "$fail" -eq 0 ]; then echo "PASS"; else echo "FAILED"; fi
exit "$fail"
