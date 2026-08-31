## Install sbx and Claude Code on Windows
``` shell
winget install -h Docker.sbx
sbx login

cd ~/my-project
sbx run claude
```

The general `sbx run` syntax is:
``` shell
sbx run [flags] [AGENT] [PATH...]
```

## `--dangerously-skip-permissions` Param
``` shell
sbx run claude --name claude-demo -- --dangerously-skip-permissions
```
Using --dangerously-skip-permissions inside Docker sbx is less risky than running it directly on the host machine. However, it still causes Claude Code to skip permission confirmations within the sandbox.
If your current project directory is mounted directly into the container, Claude Code can still modify files in your project.

## `agents` Param
``` shell
sbx run claude --name claude-demo -- agents
```
This opens the **Claude Code Agent View**.
Agent View is a **multi-session console for Claude Code**. It allows you to:
- Monitor multiple Claude Code tasks running simultaneously in a single terminal interface.
- See which sessions are currently running.
- See which sessions are waiting for your input.
- See which sessions have already completed.
- Attach to any session at any time and take over manual control.
In short, it provides a centralized dashboard for managing multiple Claude Code sessions and workflows.

## Create custom sandbox kit and run it
Kit folder structure:
```
C:\Users\<Directory>\claude-marketplace-kit\ 
└── spec.yaml
```

Main spec.yaml :
``` yaml
schemaVersion: "2"
kind: sandbox
name: claude-marketplace
version: "1.0.0"
displayName: Claude Code with Marketplace Plugins
description: Claude Code sandbox with Superpowers, Ponytail, and Caveman installed automatically.
extends: claude

permissions:
  network:
    allow:
      - github.com
      - api.github.com
      - raw.githubusercontent.com
      - objects.githubusercontent.com

setup:
  install:
    - command: |
        set -eu
        claude plugin marketplace add obra/superpowers-marketplace
        claude plugin install superpowers@superpowers-marketplace
        claude plugin marketplace add DietrichGebert/ponytail
        claude plugin install ponytail@ponytail
        claude plugin marketplace add JuliusBrussee/caveman
        claude plugin install caveman@caveman
      user: "1000"
      description: Register Claude marketplaces and install shared plugins

agentInstructions:
  content: |
    This sandbox preinstalls the following Claude Code plugins:
    - superpowers@superpowers-marketplace
    - ponytail@ponytail
    - caveman@caveman
```

Only first time created sbx sandbox have to run with kit:
``` shell
sbx run --name my-new-project --kit "C:\Data\AI-Sandbox-Projects\sbx-kits\claude-kit\claude-marketplace-kit" claude "C:\Projects\my-new-project"
```

