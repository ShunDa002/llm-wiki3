---
description: Report vault health findings. Recommends, never repairs.
allowed-tools: Read, Grep, Glob, Bash(bash scripts/wiki-lint.sh), Bash(bash scripts/verify-vault.sh), Bash(git status:*)
---

Follow `prompts/wiki-lint.md`.

That file is the canonical, agent-neutral definition of this workflow — every agent, Claude
included, runs the same steps from it. This file exists only to declare Claude Code's tool scope
above. To change what lint checks, edit `prompts/wiki-lint.md`, never here — a fork here is
exactly the drift that made this workflow unreliable across agents before.
