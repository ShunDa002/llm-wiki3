#!/usr/bin/env bash
# Self-check for lint-governance.sh: one planted defect per check, plus the negative cases that
# keep it usable. This is the Phase 4 exit evidence for "monthly lint identifies known planted
# defects" — and the negatives are the evidence for "lint precision is acceptable to reviewers",
# since a governance check that fires on correct structure gets switched off within a week.
# Run: scripts/test-lint-governance.sh
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export VAULT_TODAY=2026-08-31 VAULT_STALE_DAYS=90   # cutoff 2026-06-02, pinned so time cannot break the suite

fail=0
mk() { # <root>
  mkdir -p "$1/scripts" "$1/wiki/concepts" "$1/wiki/syntheses" "$1/wiki/sources" \
           "$1/wiki/questions" "$1/okf/projects" "$1/okf/decisions" "$1/okf/experiments" "$1/raw"
  cp "$here/lint-governance.sh" "$here/lib-vault.sh" "$1/scripts/"
  printf -- '---\ntitle: Wiki Index\n---\n# Index\n' > "$1/wiki/index.md"
  printf -- '---\ntitle: Operation Log\n---\n# Log\n' > "$1/wiki/log.md"
}

# ============================ dirty vault ==================================
dirty=$(mktemp -d)
trap 'rm -r -- "$dirty" "$clean"' EXIT
mk "$dirty"

# knowledge pages the OKF fixtures point at
printf -- '---\ntitle: Disputed Concept\nknowledge_status: disputed\nupdated: 2026-01-01\n---\nx\n' \
  > "$dirty/wiki/concepts/Disputed Concept.md"
printf -- '---\ntitle: Superseded Concept\nknowledge_status: superseded\nupdated: 2026-01-01\n---\nx\n' \
  > "$dirty/wiki/concepts/Superseded Concept.md"
# cited by another page, so superseded-page-cited fires
printf -- '---\ntitle: Citing Concept\nknowledge_status: current\nupdated: 2026-01-01\n---\n[[Superseded Concept]]\n' \
  > "$dirty/wiki/concepts/Citing Concept.md"
# a current synthesis whose parents are disputed — the one-hop case
printf -- '---\ntitle: Resolving Synthesis\nknowledge_status: current\nupdated: 2026-08-30\nbased_on:\n  - "[[Disputed Concept]]"\n---\nx\n' \
  > "$dirty/wiki/syntheses/Resolving Synthesis.md"
# stale claim block, and one with no date at all
printf -- '---\ntitle: Stale Claim Page\nknowledge_status: current\n---\n## Claim\n\nc\n\n### Last reviewed\n\n2026-01-15\n' \
  > "$dirty/wiki/concepts/Stale Claim Page.md"
printf -- '---\ntitle: Undated Claim Page\nknowledge_status: current\n---\n## Claim\n\nc\n' \
  > "$dirty/wiki/concepts/Undated Claim Page.md"
printf -- '---\ntitle: Old Question\ntype: question\nstatus: open\nupdated: 2026-02-01\n---\nq\n' \
  > "$dirty/wiki/questions/Old Question.md"

# project: no informed_by, no review_date, and (via the second project) an overdue one
printf -- '---\ntitle: Bare Project\ntype: project\nstatus: active\n---\np\n' \
  > "$dirty/okf/projects/Bare Project.md"
printf -- '---\ntitle: Late Project\ntype: project\nstatus: active\nreview_date: 2026-07-01\ninformed_by:\n  - "[[Resolving Synthesis]]"\n---\n[[Resolving Synthesis]]\n' \
  > "$dirty/okf/projects/Late Project.md"

# decision: knowledge_basis pointing at a missing page, a superseded one, a disputed one, and a
# page updated after the decision was accepted. validated_by names an experiment that tests
# something else — the asymmetry Phase 3 left open.
printf -- '---\ntitle: Loose Decision\ntype: decision\nstatus: accepted\ndecision_date: 2026-08-24\nreview_date: 2026-12-01\nknowledge_basis:\n  - "[[Ghost Page]]"\n  - "[[Superseded Concept]]"\n  - "[[Disputed Concept]]"\n  - "[[Resolving Synthesis]]"\nvalidated_by: "[[Wrong Experiment]]"\n---\n[[Resolving Synthesis]]\n' \
  > "$dirty/okf/decisions/Loose Decision.md"

# experiment: no tests_decision at all
printf -- '---\ntitle: Untethered Experiment\ntype: experiment\nstatus: complete\n---\n[[Resolving Synthesis]]\n' \
  > "$dirty/okf/experiments/Untethered Experiment.md"
# experiment: tests a decision that does not point back
printf -- '---\ntitle: Wrong Experiment\ntype: experiment\nstatus: complete\ntests_decision: "[[Loose Decision]]"\n---\n[[Resolving Synthesis]]\n' \
  > "$dirty/okf/experiments/Wrong Experiment.md"

# okf page reaching into the evidence layer with no compiled page cited at all
printf -- '---\ntitle: Raw-Only Experiment\ntype: experiment\nstatus: complete\ntests_decision: "[[Loose Decision]]"\n---\nPer [[Source - Thing]].\n' \
  > "$dirty/okf/experiments/Raw-Only Experiment.md"
printf -- '---\ntitle: Source - Thing\ntype: source\n---\ne\n' > "$dirty/wiki/sources/Source - Thing.md"

out=$(cd "$dirty" && bash scripts/lint-governance.sh); rc=$?

# Matched as "<finding-type> ... <path>" rather than a padded literal: the report's column width
# is presentation, and a test that encodes it fails on a cosmetic change. (It did, first run.)
expect() { # <label> <finding-type> [path-substring]
  if grep -qE "^$2 .*${3:-}" <<< "$out"; then echo "ok   $1"
  else echo "FAIL $1 -- no line matching: $2 ... ${3:-}"; fail=1; fi
}
reject() { # <label> <finding-type> <path-substring>
  if grep -qE "^$2 .*$3" <<< "$out"; then echo "FAIL $1 -- unexpected: $2 ... $3"; fail=1
  else echo "ok   $1"; fi
}

expect "project without knowledge"        "project-no-knowledge" "Bare Project.md"
expect "missing review date"              "okf-no-review-date" "Bare Project.md"
expect "overdue review date"              "okf-review-overdue" "Late Project.md"
expect "experiment tests no decision"     "experiment-no-decision" "Untethered Experiment.md"
expect "one-way decision/experiment link" "link-not-reciprocal"
expect "active work on disputed knowledge" "project-on-disputed-knowledge" "Late Project.md.*Resolving Synthesis.*Disputed Concept"
expect "knowledge basis page missing"     "decision-basis-missing"
expect "decision on superseded knowledge" "decision-cites-superseded"
expect "decision on disputed knowledge"   "decision-cites-disputed"
expect "knowledge changed since decision" "knowledge-changed-since-decision"
expect "okf citing evidence only"         "okf-cites-evidence-only" "Raw-Only Experiment.md"
expect "superseded page still cited"      "superseded-page-cited" "Superseded Concept.md"
expect "stale claim review date"          "claim-review-stale" "Stale Claim Page.md"
expect "claim block with no date"         "claim-review-undated" "Undated Claim Page.md"
expect "stale open question"              "question-stale" "Old Question.md"
reject "no false positive on mixed citation" "okf-cites-evidence-only" "Wrong Experiment.md"
[ "$rc" -eq 1 ] && echo "ok   exit code 1 on findings" || { echo "FAIL exit code was $rc, want 1"; fail=1; }

# ============================ clean vault ==================================
# Every check above has a correct counterpart here. This half is the precision test: a governance
# lint that cannot stay silent on a well-formed vault is worse than no governance lint.
clean=$(mktemp -d)
mk "$clean"
printf -- '---\ntitle: Good Concept\nknowledge_status: current\nupdated: 2026-08-20\n---\n## Claim\n\nc\n\n### Last reviewed\n\n2026-08-20\n' \
  > "$clean/wiki/concepts/Good Concept.md"
printf -- '---\ntitle: Good Synthesis\nknowledge_status: current\nupdated: 2026-08-20\nbased_on:\n  - "[[Good Concept]]"\n---\nx\n' \
  > "$clean/wiki/syntheses/Good Synthesis.md"
printf -- '---\ntitle: Answered Question\ntype: question\nstatus: answered\nupdated: 2026-01-01\n---\nq\n' \
  > "$clean/wiki/questions/Answered Question.md"
printf -- '---\ntitle: Good Project\ntype: project\nstatus: active\nreview_date: 2026-12-01\ninformed_by:\n  - "[[Good Synthesis]]"\n---\n[[Good Synthesis]]\n' \
  > "$clean/okf/projects/Good Project.md"
printf -- '---\ntitle: Good Decision\ntype: decision\nstatus: accepted\ndecision_date: 2026-08-24\nreview_date: 2026-12-01\nknowledge_basis:\n  - "[[Good Synthesis]]"\nvalidated_by: "[[Good Experiment]]"\n---\n[[Good Synthesis]]\n' \
  > "$clean/okf/decisions/Good Decision.md"
# Cites its own source record AND a compiled page — the exact shape that produced this suite's
# one real false positive against the live vault. It must stay silent.
printf -- '---\ntitle: Good Experiment\ntype: experiment\nstatus: complete\ntests_decision: "[[Good Decision]]"\n---\nPer [[Source - Good]] and [[Good Concept]].\n' \
  > "$clean/okf/experiments/Good Experiment.md"
printf -- '---\ntitle: Source - Good\ntype: source\n---\ne\n' > "$clean/wiki/sources/Source - Good.md"

clean_out=$(cd "$clean" && bash scripts/lint-governance.sh); clean_rc=$?
if [ "$clean_rc" -eq 0 ]; then
  echo "ok   clean vault produces no findings"
else
  echo "FAIL clean vault produced findings:"; printf '%s\n' "$clean_out" | sed 's/^/     /'; fail=1
fi

# Read-only by construction: plan §4.1 says semantic lint must not modify content silently.
before=$(cd "$clean" && find wiki okf raw -type f -exec sha256sum {} + | sort)
(cd "$clean" && bash scripts/lint-governance.sh >/dev/null 2>&1) || true
after=$(cd "$clean" && find wiki okf raw -type f -exec sha256sum {} + | sort)
[ "$before" = "$after" ] && echo "ok   lint wrote nothing" || { echo "FAIL lint modified vault content"; fail=1; }

# Documentation coverage. Round 7's cross-agent audit found `decision-basis-missing` absent from
# docs/phase-4/lint-layers.md, and a follow-up audit found 7 of the 15 types with no fix-policy row
# at all — while "auto-fix eligibility is documented by finding type" is a Phase 4 exit criterion.
# A finding type nobody documented has no fix policy, so this is a real defect class, not tidiness.
undoc=""
for t in $(grep -oE 'report "[a-z][a-z-]+"' "$here/lint-governance.sh" | sed 's/report "//; s/"//' | sort -u); do
  for doc in "$here/../docs/phase-4/lint-layers.md" "$here/../prompts/wiki-lint.md"; do
    [ -f "$doc" ] || continue
    grep -q -- "$t" "$doc" || undoc="$undoc$t -> $(basename "$doc")"$'\n'
  done
done
if [ -z "$undoc" ]; then
  echo "ok   every finding type is documented in lint-layers.md and prompts/wiki-lint.md"
else
  echo "FAIL undocumented finding types:"; printf '%s' "$undoc" | sed 's/^/     /'; fail=1
fi

if [ "$fail" -eq 0 ]; then echo "PASS"; else echo "FAILED"; echo "--- dirty output ---"; echo "$out"; fi
exit "$fail"
