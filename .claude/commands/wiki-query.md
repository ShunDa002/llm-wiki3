---
description: Answer a question from vault knowledge, with citations
argument-hint: <question>
allowed-tools: Read, Grep, Glob
---

Follow `prompts/wiki-query.md` for this question: $ARGUMENTS

That file is the canonical, agent-neutral definition of this workflow — every agent, Claude
included, runs the same steps from it. This file exists only to declare Claude Code's tool scope
above. To change what query does, edit `prompts/wiki-query.md`, never here — a fork here is
exactly the drift that made this workflow unreliable across agents before.
