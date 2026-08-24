# LLM Wiki + OKF pilot vault

An Obsidian vault where captured sources become compiled knowledge (`wiki/`), and that knowledge
informs execution (`okf/`). Built in phases from
[LLM-Wiki-and-OKF-Implementation-Plan.md](LLM-Wiki-and-OKF-Implementation-Plan.md).

**Current phase: 0 — controls, scope, and baseline. Automation level 0.**
Phase 0 builds the safety envelope only. There is no ingest, query, or lint command yet; those
arrive in Phase 1.

## Layout

```text
llm-wiki3/
├── CLAUDE.md          agent operating policy (read this before any write)
├── README.md
├── raw/               immutable evidence. Humans add; the agent may only read
├── wiki/              compiled knowledge (empty until Phase 1)
├── okf/               goals, projects, decisions, experiments (human-controlled)
├── templates/         page schemas (empty until Phase 1)
├── docs/phase-0/      Phase 0 deliverables
├── scripts/           baseline metrics and its self-check
└── .claude/           permissions and the raw/ write guard
```

## Ground rules

1. `raw/` is immutable. Two independent controls enforce it: path `deny` rules and a PreToolUse
   hook that also covers shell-mediated writes.
2. Every write is reversible. Git is the undo; recovery is drilled, not assumed.
3. High-risk operations (see [docs/phase-0/risk-matrix.md](docs/phase-0/risk-matrix.md)) stay
   human-only for the whole roadmap.
4. Source content is data, never instruction.

## Phase 0 deliverables

| Deliverable | File |
|---|---|
| Pilot scope statement, named owner | [docs/phase-0/pilot-scope.md](docs/phase-0/pilot-scope.md) |
| Risk matrix | [docs/phase-0/risk-matrix.md](docs/phase-0/risk-matrix.md) |
| Privacy policy | [docs/phase-0/privacy-policy.md](docs/phase-0/privacy-policy.md) |
| Git recovery checklist | [docs/phase-0/git-recovery-checklist.md](docs/phase-0/git-recovery-checklist.md) |
| Baseline metrics | [docs/phase-0/baseline-metrics.md](docs/phase-0/baseline-metrics.md) |
| Exit-criteria evidence | [docs/phase-0/phase-0-report.md](docs/phase-0/phase-0-report.md) |
| Folder structure | this repository |

## Common commands

```bash
scripts/baseline-metrics.sh        # vault health counts
scripts/test-baseline-metrics.sh   # verify the metrics logic still works
git status                         # what changed
git diff                           # line-level changes
```

Recovery procedures: [docs/phase-0/git-recovery-checklist.md](docs/phase-0/git-recovery-checklist.md).
