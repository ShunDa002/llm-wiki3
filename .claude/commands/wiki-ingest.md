---
description: Integrate one raw source into the Wiki as a reviewed transaction
argument-hint: <path under raw/>
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(sha256sum:*), Bash(git status:*), Bash(git diff:*), Bash(bash scripts/verify-vault.sh)
---

Follow `prompts/wiki-ingest.md` for this input path: `$1`

That file is the canonical, agent-neutral definition of this workflow — every agent, Claude
included, runs the same steps from it. This file exists only to declare Claude Code's tool scope
above. To change what ingest does, edit `prompts/wiki-ingest.md`, never here — a fork here is
exactly the drift that made this workflow unreliable across agents before.
