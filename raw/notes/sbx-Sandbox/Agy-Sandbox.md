# Notes: Installing Antigravity CLI Inside Docker sbx

## Purpose

This note summarizes how Antigravity CLI (`agy`) was installed and launched inside Docker sbx for the project workspace:

## 1. Initial Goal

The original goal was to create a separate Antigravity sandbox named:

```text
agy-demo-project
```

Run:

```cmd
cd C:\Data\AI-Sandbox-Projects\demo-project
sbx run shell --name agy-demo-project .
```

---

## 2. Enter the Sandbox

From Windows Host CMD:

```cmd
cd C:\Data\AI-Sandbox-Projects\demo-project
sbx exec -it agy-demo-project bash
```

Inside the sandbox, verify identity:

```bash
whoami
pwd
hostname
uname -a
```

Expected sandbox identity:

```text
User: agent
Home: /home/agent
Hostname: agy-demo-project
Linux environment
```

---

## 3. Install Antigravity CLI

The Antigravity CLI installer URL was:

```bash
https://antigravity.google/cli/install.sh
```

The intended install command was:

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

At first, the installer failed because the sandbox network policy blocked the domain:

```text
Blocked by network policy: domain antigravity.google:443
```

---

## 4. Allow Installer Domain in Docker Sandbox Policy

Exit the sandbox:

```bash
exit
```

On Windows Host CMD, allow the installer domain only for this sandbox:

```cmd
sbx policy allow network --sandbox agy-demo-project antigravity.google
```

Then verify:

```cmd
sbx policy ls agy-demo-project
```

Re-enter the sandbox:

```cmd
cd C:\Data\AI-Sandbox-Projects\demo-project
sbx exec -it agy-demo-project bash
```

Re-install again:

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

---

## 5. Allow Release Manifest Server

After allowing `antigravity.google`, the installer downloaded successfully but failed at:

```text
Querying release repository...
Fatal: Could not connect to the release server to download the manifest.
```

Exit the sandbox:

```bash
exit
```

Allow the release server only for this sandbox:

```cmd
sbx policy allow network --sandbox agy-demo-project antigravity-cli-auto-updater-974169037036.us-central1.run.app
```

Verify policy rules:

```cmd
sbx policy ls agy-demo-project
```

Expected allowed domains include:

```text
antigravity.google
antigravity-cli-auto-updater-974169037036.us-central1.run.app
```

---

## 6. Retry Installation

Re-enter sandbox:

```cmd
cd C:\Data\AI-Sandbox-Projects\demo-project
sbx exec -it agy-demo-project bash
```

Inside sandbox:

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```



After successful installation, reload PATH:

```bash
source ~/.bashrc 2>/dev/null || true
source ~/.profile 2>/dev/null || true
export PATH="$HOME/.local/bin:$PATH"
```

Make PATH persistent:

```bash
grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Verify installation:

```bash
which agy
agy --version
ls -l "$(which agy)"
```

Verified result:

```text
/home/agent/.local/bin/agy
agy version: 1.0.3
-rwxr-xr-x 1 agent agent ... /home/agent/.local/bin/agy
```

---

## 7. Verified Sandbox Isolation State

The following checks were run inside the sandbox:

```bash
echo "User: $(whoami)"
echo "Home: $HOME"
echo "PWD: $(pwd)"
hostname
uname -a
which agy
agy --version
ls -l "$(which agy)"
```

Verified output:

```text
User: agent
Home: /home/agent
hostname: gemini-demo-project
agy path: /home/agent/.local/bin/agy
agy version: 1.0.3
```

Meaning:

```text
Antigravity CLI is installed inside the sandbox user environment.
It is not being loaded from Windows Host.
```

---

## 8. Verified Antigravity and Gemini Config Locations

Inside sandbox:

```bash
ls -ld ~/.gemini 2>/dev/null || echo "No ~/.gemini directory found"
ls -ld ~/.gemini/antigravity-cli 2>/dev/null || echo "No Antigravity config directory found yet"
ls -l ~/.gemini/antigravity-cli/settings.json 2>/dev/null || echo "No Antigravity settings.json found yet"
stat -c "%a %U:%G %n" ~/.gemini/antigravity-cli/settings.json 2>/dev/null
```

Verified result:

```text
/home/agent/.gemini
/home/agent/.gemini/antigravity-cli
/home/agent/.gemini/antigravity-cli/settings.json
600 agent:agent /home/agent/.gemini/antigravity-cli/settings.json
```

Gemini OAuth credential check:

```bash
ls -l ~/.gemini/oauth_creds.json 2>/dev/null && echo "Gemini OAuth credential file exists"
stat -c "%a %U:%G %n" ~/.gemini/oauth_creds.json 2>/dev/null
```

Verified result:

```text
Gemini OAuth credential file exists
600 agent:agent /home/agent/.gemini/oauth_creds.json
```

Important safety rule:

```text
Do not print, copy, share, or commit ~/.gemini/oauth_creds.json.
Do not run grep commands that may print OAuth tokens.
```

Avoid:

```bash
cat ~/.gemini/oauth_creds.json
grep -R "token" ~/.gemini
grep -R "ya29" ~/.gemini
```

---

## 9. Create Windows Launcher for Antigravity CLI

Create this file on Windows Host:

```text
C:\Data\AI-Sandbox-Projects\run-agy.cmd
```

Recommended safe launcher:

```cmd
@echo off
cd /d C:\Data\AI-Sandbox-Projects\demo-project

sbx exec -it ^
  -e TERM=xterm-256color ^
  -e COLORTERM=truecolor ^
  -w /c/Data/AI-Sandbox-Projects/demo-project ^
  gemini-demo-project ^
  bash -ilc "echo Sandbox name: gemini-demo-project; echo User: $(whoami); echo Home: $HOME; echo Working directory: $(pwd); echo agy path: $(which agy 2>/dev/null || echo agy-not-found); echo; exec agy"
```

Run this launcher from Windows Terminal.

---

## 10. Verified Launcher Output

When launching Antigravity CLI through `run-agy.cmd`, the output was:

```text
Sandbox name: gemini-demo-project
User: agent
Home: /home/agent
Working directory: /c/Data/AI-Sandbox-Projects/demo-project
agy path: /home/agent/.local/bin/agy
```

This confirms:

```text
Antigravity CLI launches inside Docker Sandbox.
It runs as sandbox user agent.
It uses sandbox home /home/agent.
It starts inside the intended project workspace.
It uses sandbox-installed agy binary.
```

---

## 11. Important Working Directory Note

Running this command manually:

```cmd
sbx exec -it gemini-demo-project bash
```

may enter the default sandbox directory:

```text
/home/agent/workspace
```

For Antigravity CLI, always launch with `-w` to force the intended project path:

```cmd
sbx exec -it -w /c/Data/AI-Sandbox-Projects/demo-project gemini-demo-project bash
```

The launcher already includes:

```cmd
-w /c/Data/AI-Sandbox-Projects/demo-project
```

So `agy` starts in the correct project workspace.

---

## 12. Recommended Antigravity CLI First-Run Settings

When running:

```bash
agy
```

Use safe first-run choices:

```text
Login: Google OAuth / Google Sign-In
Workspace trust: trust only /c/Data/AI-Sandbox-Projects/demo-project
Permission mode: request-review
```

Avoid unsafe/autonomous modes until fully verified:

```text
always-proceed
dangerously skip permissions
YOLO mode
```

Recommended default:

```text
request-review
```

---

## 13. Optional Verification Inside Antigravity CLI

Inside Antigravity CLI, if shell mode is supported, run:

```text
!whoami
!pwd
!which agy
```

Expected:

```text
agent
/c/Data/AI-Sandbox-Projects/demo-project
/home/agent/.local/bin/agy
```

This confirms Antigravity CLI shell commands execute inside the sandbox context.

---

## 14. Host-Side Verification

On Windows Host CMD:

```cmd
where agy
```

Expected if Antigravity CLI is only installed inside sandbox:

```text
INFO: Could not find files for the given pattern(s).
```

Check sandbox list:

```cmd
sbx ls
```

Expected relevant sandbox:

```text
gemini-demo-project    shell    running/stopped    C:\Data\AI-Sandbox-Projects\demo-project
```

Check network policy:

```cmd
sbx policy ls gemini-demo-project
```

Expected allowed Antigravity-related domains:

```text
antigravity.google
antigravity-cli-auto-updater-974169037036.us-central1.run.app
```

Avoid broad/global network allow rules such as:

```cmd
sbx policy allow network -g "**"
```

Use sandbox-scoped allow rules only.

---

## 15. Final Setup Summary

Final structure:

```text
C:\Data\AI-Sandbox-Projects\
│
├── demo-project\
│   └── project files
│
├── run-gemini.cmd
└── run-agy.cmd
```

Final sandbox usage:

```text
gemini-demo-project
    ├── Gemini CLI
    └── Antigravity CLI / agy
```

Final verified Antigravity launch state:

```text
Sandbox name: gemini-demo-project
User: agent
Home: /home/agent
Working directory: /c/Data/AI-Sandbox-Projects/demo-project
agy path: /home/agent/.local/bin/agy
```

Conclusion:

```text
Antigravity CLI is installed inside the sandbox, launches through run-agy.cmd, uses the intended project workspace, and stores its settings under the sandbox user's /home/agent directory.
```
