# Notes: Running Copilot CLI and Gemini CLI Inside Docker Sandbox

## Goal

Run AI CLI tools inside Docker Sandboxes / microVM sandbox instead of directly on the Windows Host.

```text
Host OS: Windows 11
Sandbox tool: Docker Sandboxes CLI, sbx
Project folder:
C:\Data\AI-Sandbox-Projects\demo-project
```

Security goals:

```text
1. AI CLI runs inside sandbox, not directly on Host.
2. Host sensitive paths such as C:\Users, C:\Windows, C:\ProgramData are not accessible.
3. Copilot CLI uses host-side token/secret injection.
4. Gemini CLI uses Google OAuth inside a dedicated sandbox.
5. Sandbox workspace is intentionally shared, so only put safe project files inside it.
```

---

# Part 1: Copilot CLI Inside Sandbox Using Token / Secret Injection

## 1. Create project folder

On Windows Host CMD:

```cmd
mkdir C:\Data\AI-Sandbox-Projects\demo-project
cd C:\Data\AI-Sandbox-Projects\demo-project
```

---

## 2. Store GitHub token using `sbx secret`

Use a GitHub fine-grained PAT or supported Copilot token.

Do **not** pass the token directly in the command line.

Run:

```cmd
sbx secret set -g github
```

Paste the GitHub token when prompted.

Verify:

```cmd
sbx secret ls
```

Expected:

```text
github
```

---

## 3. Create / run Copilot sandbox

```cmd
cd C:\Data\AI-Sandbox-Projects\demo-project
sbx run copilot --name copilot-demo-project .
```

If the sandbox already exists and you want a clean setup:

```cmd
sbx rm copilot-demo-project
sbx run copilot --name copilot-demo-project .
```

---

## 4. Enter Copilot sandbox shell

Open another Host CMD:

```cmd
sbx exec -it copilot-demo-project bash
```

If `bash` does not work:

```cmd
sbx exec -it copilot-demo-project sh
```

---

## 5. Verify Copilot token injection

Inside sandbox shell:

```bash
env | grep -Ei 'COPILOT|GH_TOKEN|GITHUB_TOKEN|TOKEN|GITHUB|GH' || true
```

Expected safe result:

```text
GH_TOKEN=gho_sbxproxymanaged000000000000000000000
```

Meaning:

```text
The real GitHub token is not directly exposed inside the sandbox.
Docker Sandbox proxy manages the real token from Host side.
```

Also verify GitHub API authentication:

```bash
curl -sS -D /tmp/github_headers.txt -o /tmp/github_user.json -w "%{http_code}\n" https://api.github.com/user
cat /tmp/github_user.json
```

Expected:

```text
200
```

The JSON should show your GitHub account.

> Do **not** paste the full user output publicly if it contains email or other personal information.

---

## 6. Check Copilot local files for obvious token leak

Inside sandbox:

```bash
grep -R -Eio 'github_pat_[A-Za-z0-9_]+|gho_[A-Za-z0-9_]+|ghp_[A-Za-z0-9_]+' ~/.copilot 2>/dev/null || echo "No obvious token string under ~/.copilot"
```

Expected:

```text
No obvious token string under ~/.copilot
```

Do **not** run:

```bash
cat ~/.copilot/config.json
cat ~/.copilot/session-store.db
```

These files may contain session metadata.

---

# Part 2: Gemini CLI Inside Sandbox Using Google OAuth

Important difference:

```text
Copilot token injection:
Real token stays Host-side/proxy-managed.

Gemini OAuth:
OAuth credential is stored inside sandbox at:
~/.gemini/oauth_creds.json
```

This is expected for OAuth login. The safe rule is:

```text
Do not print, copy, share, or commit ~/.gemini/oauth_creds.json.
Delete the sandbox when you no longer need the OAuth session.
```

---

## 1. Remove Google API key secret if using OAuth-only

On Host CMD:

```cmd
sbx secret ls
```

If you see a `google` secret and want OAuth-only mode:

```cmd
sbx secret rm -g google
```

Verify:

```cmd
sbx secret ls
```

Expected:

```text
No google secret
```

---

## 2. Create Gemini sandbox shell

Use a shell sandbox because the built-in Gemini template may use API-key/proxy style auth.

```cmd
cd C:\Data\AI-Sandbox-Projects\demo-project
sbx run shell --name gemini-demo-project .
```

If the sandbox already exists and you want a clean setup:

```cmd
sbx rm gemini-demo-project
sbx run shell --name gemini-demo-project .
```

If not attached automatically:

```cmd
sbx exec -it gemini-demo-project bash
```

---

## 3. Install Gemini CLI inside sandbox

Inside sandbox shell:

```bash
node --version
npm --version
```

Install Gemini CLI:

```bash
npm install -g @google/gemini-cli
```

Verify:

```bash
which gemini
gemini --version
```

If `node` or `npm` is missing:

```bash
apt-get update
apt-get install -y nodejs npm
npm install -g @google/gemini-cli
```

---

## 4. Confirm no API-key auth is active

Inside sandbox:

```bash
env | grep -Ei 'GEMINI_API_KEY|GOOGLE_API_KEY' || echo "No API key env found"
```

For OAuth-only, expected:

```text
No API key env found
```

If you see:

```text
GEMINI_API_KEY=proxy-managed
GOOGLE_API_KEY=proxy-managed
```

Then Google API-key injection is still active. Remove the Host `google` secret and recreate the sandbox.

---

## 5. Login Gemini CLI using Google OAuth

Inside sandbox:

```bash
gemini
```

Choose:

```text
Login with Google
```

Complete browser OAuth login.

After login, Gemini will create files under:

```bash
~/.gemini
```

Important file:

```bash
~/.gemini/oauth_creds.json
```

This file contains OAuth credentials. Do **not** print it.

---

## 6. Verify Gemini OAuth login safely

Do **not** grep for `ya29` or `1//`, because that prints real tokens.

Use safe checks only:

```bash
ls -l ~/.gemini/oauth_creds.json 2>/dev/null && echo "OAuth credential file exists"
stat -c "%a %U:%G %n" ~/.gemini/oauth_creds.json 2>/dev/null
```

Expected permission:

```text
600 agent:agent /home/agent/.gemini/oauth_creds.json
```

Verify Gemini works:

```bash
gemini -p "Confirm Gemini CLI is authenticated. Reply with a short status only."
```

---

## 7. Create Windows launcher for Gemini CLI

Because the sandbox was created as a shell sandbox, running this will not automatically open Gemini CLI:

```cmd
sbx run gemini-demo-project
```

Create a `.cmd` file, for example:

```text
C:\Data\AI-Sandbox-Projects\run-gemini.cmd
```

Content:

```cmd
@echo off
cd /d C:\Data\AI-Sandbox-Projects\demo-project
sbx exec -it -e TERM=xterm-256color -e COLORTERM=truecolor -w /c/Data/AI-Sandbox-Projects/demo-project gemini-demo-project bash -ilc "exec gemini"
```

Recommended: run this `.cmd` from **Windows Terminal** for better cursor/color behavior.

---

# Part 3: Verify Sandbox Isolation From Host

Run these checks for both sandboxes:

```cmd
sbx exec -it copilot-demo-project bash
```

or:

```cmd
sbx exec -it gemini-demo-project bash
```

---

## 1. Verify you are inside Linux sandbox

Inside sandbox:

```bash
whoami
hostname
pwd
uname -a
cat /etc/os-release
```

Expected example:

```text
whoami      -> agent
hostname    -> copilot-demo-project or gemini-demo-project
pwd         -> /home/agent/workspace or /c/Data/AI-Sandbox-Projects/demo-project
uname       -> Linux ...
os-release  -> Ubuntu ...
```

This confirms the CLI is not running directly in Windows Host.

---

## 2. Verify Host sensitive directories are not accessible

Inside sandbox:

```bash
ls -la /c/Users 2>/dev/null || echo "No access to /c/Users"
ls -la /c/Windows 2>/dev/null || echo "No access to /c/Windows"
ls -la /c/ProgramData 2>/dev/null || echo "No access to /c/ProgramData"
```

Expected:

```text
No access to /c/Users
No access to /c/Windows
No access to /c/ProgramData
```

This is a good sign that Host sensitive system/user directories are not exposed.

---

## 3. Check mounted workspace scope

Inside sandbox:

```bash
ls -la /c
ls -la /c/Data
ls -la /c/Data/AI-Sandbox-Projects
ls -la /c/Data/AI-Sandbox-Projects/demo-project
```

Expected:

```text
Sandbox can access the project/workspace area.
Sandbox should not access unrelated Host directories.
```

Important note:

```text
Files under C:\Data\AI-Sandbox-Projects may be visible depending on how sbx mounted the workspace.
Only put files there that are safe for AI agents to read/modify.
```

---

## 4. Verify Docker daemon isolation

Inside sandbox:

```bash
docker ps
docker info | head -50
```

On Host CMD:

```cmd
docker ps
```

Expected:

```text
Sandbox docker ps should not show Host Docker containers.
Host docker ps should not show sandbox-internal containers.
```

This confirms the sandbox has a separate Docker daemon.

---

## 5. Verify credentials are not accidentally exposed

### Copilot

Inside Copilot sandbox:

```bash
env | grep -Ei 'COPILOT|GH_TOKEN|GITHUB_TOKEN|TOKEN|GITHUB|GH' || true
```

Good:

```text
GH_TOKEN=gho_sbxproxymanaged000000000000000000000
```

Check no obvious token string:

```bash
grep -R -Eio 'github_pat_[A-Za-z0-9_]+|gho_[A-Za-z0-9_]+|ghp_[A-Za-z0-9_]+' ~/.copilot 2>/dev/null || echo "No obvious token string under ~/.copilot"
```

---

### Gemini

Inside Gemini sandbox:

```bash
env | grep -Ei 'GEMINI_API_KEY|GOOGLE_API_KEY' || echo "No API key env found"
```

For OAuth-only:

```text
No API key env found
```

Check OAuth credential file exists without printing it:

```bash
ls -l ~/.gemini/oauth_creds.json 2>/dev/null && echo "OAuth credential file exists"
stat -c "%a %U:%G %n" ~/.gemini/oauth_creds.json 2>/dev/null
```

Do **not** run:

```bash
cat ~/.gemini/oauth_creds.json
grep -R 'ya29\|1//' ~/.gemini
```

Those commands may print sensitive OAuth tokens.

---

# Part 4: Daily Usage Commands

## Open Copilot CLI sandbox

```cmd
cd C:\Data\AI-Sandbox-Projects\demo-project
sbx run copilot --name copilot-demo-project .
```

If the sandbox already exists, you can also enter shell:

```cmd
sbx exec -it copilot-demo-project bash
```

---

## Open Gemini CLI sandbox

Use your launcher `.cmd`:

```cmd
C:\Data\AI-Sandbox-Projects\run-gemini.cmd
```

Or manually:

```cmd
cd C:\Data\AI-Sandbox-Projects\demo-project
sbx exec -it -e TERM=xterm-256color -e COLORTERM=truecolor -w /c/Data/AI-Sandbox-Projects/demo-project gemini-demo-project bash -ilc "exec gemini"
```

---

## Stop sandbox

```cmd
sbx stop copilot-demo-project
sbx stop gemini-demo-project
```

---

## Delete sandbox and remove local credentials

```cmd
sbx rm copilot-demo-project
sbx rm gemini-demo-project
```

For Gemini OAuth, deleting the sandbox removes:

```text
~/.gemini/oauth_creds.json
```

If OAuth was exposed or no longer needed, revoke it from Google Account permissions page as well.

---

# Final Security Notes

```text
Copilot:
Best setup is host-side sbx secret injection.
Real GitHub token should appear only as proxy-managed inside sandbox.

Gemini:
OAuth login stores credentials inside sandbox.
This is normal.
Keep the sandbox dedicated.
Do not print oauth_creds.json.
Do not run untrusted scripts in that sandbox.
Delete sandbox when done.

Host isolation:
Sandbox should not access /c/Users, /c/Windows, or /c/ProgramData.
Workspace folder is shared intentionally, so keep it clean and dedicated.
```
