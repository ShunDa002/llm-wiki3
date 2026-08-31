---
description: Apply a Wiki synthesis to a named OKF project or proposed decision, plan first.
argument-hint: <synthesis> <project-or-decision>
allowed-tools: Read, Grep, Glob, Edit, Write(./okf/**), Write(./wiki/log.md), Bash(bash scripts/check-schema.sh:*)
---

Follow `prompts/bridge-apply.md` for these inputs: $ARGUMENTS

That file is the canonical, agent-neutral definition of this workflow. This file exists only to
declare Claude Code's tool scope above. To change what bridge-apply does, edit
`prompts/bridge-apply.md`, never here.
