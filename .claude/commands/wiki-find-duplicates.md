---
description: Report duplicate and fragmented pages. Proposes, never merges.
argument-hint: [proposed page title, or empty to scan the vault]
allowed-tools: Read, Grep, Glob, Bash(bash scripts/find-duplicates.sh:*)
---

Follow `prompts/wiki-find-duplicates.md` for this input: $ARGUMENTS

That file is the canonical, agent-neutral definition of this workflow — every agent, Claude
included, runs the same steps from it. This file exists only to declare Claude Code's tool scope
above. To change what duplicate detection does, edit `prompts/wiki-find-duplicates.md`, never here
— a fork here is exactly the drift that made this workflow unreliable across agents before.
