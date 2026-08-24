# Phase 0 deliverable: baseline metrics

Date recorded: 2026-08-24
Phase: 0, before any ingestion.

The point of a baseline is to be able to answer, later, whether the system improved actual work
or only produced more Markdown. Numbers recorded after the Wiki exists cannot answer that.

## Automated counts

Produced by `scripts/baseline-metrics.sh` (read-only; self-checked by
`scripts/test-baseline-metrics.sh`).

```text
Notes (wiki/ + okf/ + raw/)      : 0
Notes without a sources: field   : 0
Duplicate note filenames         : 0
Broken internal wikilinks        : 0
Orphan notes (no inbound link)   : 0
OKF decisions                    : 0
  without knowledge_basis        : 0
OKF experiments                  : 0
  with a documented conclusion   : 0 (n/a, 0 records)
```

All zeros because the pilot vault starts empty. This is the correct baseline for a fresh vault,
and it is a real measurement, not a placeholder: every defect count starts at zero, so any
defect that appears later was introduced by the pilot.

The script was verified against a fixture vault with deliberately planted defects — a duplicate
filename, two dangling wikilinks, a note without sources, an experiment with no conclusion — and
reported each one. Zeros here mean "clean", not "not looking".

## Manual measurements (owner to record before first ingest)

These need a human with a stopwatch on real work; no script can infer them.

| Metric | Baseline | How measured |
|---|---|---|
| Average time to find supporting material | _to record_ | Time 5 real lookups in the current workflow, take the mean |
| Average time to create a useful synthesis | _to record_ | Time 2 comparisons or trade-off write-ups end to end |
| Number of duplicate notes (existing workflow) | _to record_ | Count in the pre-pilot note collection, if any |
| Number of existing notes without sources | _to record_ | Same collection |
| Number of project decisions without recorded rationale | _to record_ | Count current decisions lacking a written why |
| Percentage of experiments with documented conclusions | _to record_ | Concluded / total in current practice |

Leaving these blank is a decision, not an oversight: if they are never recorded, the Phase 5
question "did retrieval get better?" can only be answered relatively, from the first automated
run onward.

## Re-measurement points

- After the first 5 ingestions (Phase 1 exit).
- After 20 ingestions (Phase 2 exit).
- Then monthly, per the Phase 4 cadence.

Re-run with:

```bash
scripts/baseline-metrics.sh
```
