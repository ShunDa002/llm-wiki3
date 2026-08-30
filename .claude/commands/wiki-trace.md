---
description: Trace a claim, page, or decision back to raw evidence. Read-only.
argument-hint: <claim, page, or OKF record>
allowed-tools: Read, Grep, Glob
---

Follow `prompts/wiki-trace.md` for this input: $ARGUMENTS

That file is the canonical, agent-neutral definition of this workflow — every agent, Claude
included, runs the same steps from it. This file exists only to declare Claude Code's tool scope
above. To change what tracing does, edit `prompts/wiki-trace.md`, never here — a fork here is
exactly the drift that made this workflow unreliable across agents before.
