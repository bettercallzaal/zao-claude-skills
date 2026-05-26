---
name: quad
description: Manage QuadWork — the local 4-agent (Head / Dev / RE1 / RE2) dev team dashboard at http://127.0.0.1:8400. Use when Zaal types /quad. Single auto-dispatching command that inspects state and does the right next thing (start server, fix pin, trust worktrees, open dashboard, report status). Dashboard is local-only; agents run on Zaal's laptop using Claude Max + optional ChatGPT Codex auth.
---

# /quad — QuadWork Control (Single Auto-Dispatching Command)

Base directory: `~/.claude/skills/quad`

QuadWork v1.12.0 runs 4 local AI agents (Head + Dev + Reviewer1 + Reviewer2) against a GitHub repo. Head files issues, Dev codes, both reviewers verify, Head merges.

Dashboard: `http://127.0.0.1:8400` · Install state as of 2026-04-24: codex + claude + quadwork + AgentChattr all installed.

## The Pattern

Zaal types `/quad` (optionally with a project id). The skill inspects state and does the right thing automatically. No sub-commands to memorize.

```
/quad                      # auto-detect everything, bring the system to ready
/quad <project-id>         # same, scoped to a specific project
/quad stop                 # override: kill everything
/quad open                 # override: just open the dashboard
```

That's it. Internally the skill runs a decision tree that does what `start`, `doctor`, `fix-pin`, `trust`, and status reporting used to do separately.

## Decision Tree — What `/quad [project-id]` Does

Run top-to-bottom, stop at first action that applies:

### Step 1 — Resolve Target Project

```bash
ARG="${1:-}"
[ "$ARG" = "stop" ] && { quadwork stop 2>/dev/null; pkill -f quadwork 2>/dev/null; pkill -f 'python.*run\.py' 2>/dev/null; echo "Stopped."; exit 0; }
[ "$ARG" = "open" ] && { open http://127.0.0.1:8400/; exit 0; }

# Project resolution — if no arg, use first project in config, else use arg
PROJ=$(python3 -c "
import json, os, sys
arg = '$ARG'
p = os.path.expanduser('~/.quadwork/config.json')
try:
    d = json.load(open(p))
    projs = d.get('projects', [])
    if arg:
        match = next((p for p in projs if p.get('id')==arg), None)
        print(match.get('id') if match else '')
    elif len(projs)==1:
        print(projs[0].get('id'))
    elif projs:
        print('AMBIGUOUS:' + ','.join(p.get('id') for p in projs))
    else:
        print('NONE')
except FileNotFoundError:
    print('NOCONFIG')
")
```

Handle cases:
- `NOCONFIG` → QuadWork never set up. Tell Zaal: `! npx quadwork init` (interactive). Exit.
- `NONE` → QuadWork set up but no projects. Start server if down, open dashboard, tell Zaal: "Click Add Your First Project."
- `AMBIGUOUS:a,b,c` → Multiple projects. Tell Zaal: "/quad <project-id> — pick from: a, b, c". Exit.
- Otherwise: continue with `$PROJ`.

### Step 2 — Start Server If Down

```bash
if ! lsof -iTCP:8400 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Starting QuadWork..."
  cd ~ && nohup quadwork start > ~/.quadwork/server.log 2>&1 &
  disown
  # wait up to 30s
  for i in $(seq 1 15); do
    lsof -iTCP:8400 -sTCP:LISTEN >/dev/null 2>&1 && break
    sleep 2
  done
fi
```

### Step 3 — Doctor + Auto-Fix Pin Drift

```bash
DOCTOR=$(quadwork doctor 2>&1)
if echo "$DOCTOR" | grep -q "\[DIFF\] project:$PROJ"; then
  echo "Pin drift detected on $PROJ. Auto-fixing (doc 492)..."
  pkill -f quadwork 2>/dev/null; pkill -f 'python.*run\.py' 2>/dev/null; sleep 2
  AC="$HOME/.quadwork/$PROJ/agentchattr"
  EXPECTED=$(echo "$DOCTOR" | awk '/Expected pin:/ {print $3}')
  cd "$AC" && git fetch origin --quiet 2>/dev/null && git checkout "$EXPECTED" -- run.py config_loader.py 2>/dev/null
  .venv/bin/pip install -q -r requirements.txt 2>/dev/null
  cd ~ && nohup quadwork start > ~/.quadwork/server.log 2>&1 &
  disown
  sleep 10
fi
```

### Step 4 — Audit + Auto-Trust Worktrees

```bash
WORKING_DIR=$(python3 -c "
import json, os
p = os.path.expanduser('~/.quadwork/config.json')
d = json.load(open(p))
proj = next((p for p in d.get('projects',[]) if p.get('id')=='$PROJ'), None)
print(proj.get('working_dir') if proj else '')
")

if [ -n "$WORKING_DIR" ]; then
  # Audit — fail loud if any worktree has suspicious content
  AUDIT_OK=1
  for suffix in "" -head -dev -re1 -re2; do
    WT="${WORKING_DIR}${suffix}"
    [ -d "$WT" ] || continue
    [ -e "$WT/.git" ] || { echo "AUDIT FAIL $WT: no .git (refusing to auto-trust)"; AUDIT_OK=0; }
  done

  if [ "$AUDIT_OK" = 1 ]; then
    python3 <<PY
import json, shutil, time, os
from pathlib import Path
p = Path.home() / '.claude.json'
if not p.exists():
    print('no ~/.claude.json — skipping trust')
else:
    backup = p.with_suffix(f'.json.bak-{int(time.time())}')
    shutil.copy(p, backup)
    d = json.load(open(p))
    projs = d.setdefault('projects', {})
    base = '$WORKING_DIR'
    changed = 0
    for suffix in ['', '-head', '-dev', '-re1', '-re2']:
        wt = base + suffix
        if not os.path.isdir(wt):
            continue
        entry = projs.setdefault(wt, {})
        if not entry.get('hasTrustDialogAccepted'):
            entry['hasTrustDialogAccepted'] = True
            entry['hasCompletedProjectOnboarding'] = True
            entry.setdefault('allowedTools', [])
            entry.setdefault('mcpServers', {})
            entry.setdefault('enabledMcpjsonServers', [])
            entry.setdefault('disabledMcpjsonServers', [])
            entry.setdefault('mcpContextUris', [])
            changed += 1
    json.dump(d, open(p, 'w'), indent=2)
    if changed:
        print(f'Pre-trusted {changed} new worktree(s). Backup: {backup.name}')
PY
  fi
fi
```

### Step 5 — Report + Open Dashboard

```bash
# Summary
DASH_UP=$(lsof -iTCP:8400 -sTCP:LISTEN >/dev/null 2>&1 && echo UP || echo DOWN)
AC_UP=$(lsof -iTCP:8300 -sTCP:LISTEN >/dev/null 2>&1 && echo UP || echo DOWN)
curl -s http://127.0.0.1:8400/api/projects 2>/dev/null | python3 -c "
import json, sys
d = json.loads(sys.stdin.read() or '{\"projects\":[]}')
proj = next((p for p in d.get('projects',[]) if p.get('id')=='$PROJ'), None)
if proj:
    print(f\"Project: {proj.get('id')} · {proj.get('repo')}\")
    print(f\"Agents: {proj.get('agentCount',0)} · State: {proj.get('state','unknown')} · Open PRs: {proj.get('openPrs',0)}\")
    last = proj.get('lastActivity')
    if last: print(f\"Last activity: {last}\")
"
echo "Dashboard: $DASH_UP on 8400 · AgentChattr: $AC_UP on 8300"

# Open if not already open (macOS will reuse existing tab if one exists)
open http://127.0.0.1:8400/ 2>/dev/null

# Next-action hint (chooses ONE actionable line based on state)
echo ""
if [ "$DASH_UP" = "DOWN" ]; then
  echo "NEXT: server won't start. Run 'quadwork doctor' manually and paste output."
elif [ "$AC_UP" = "DOWN" ]; then
  echo "NEXT: AgentChattr down. Pin may have re-drifted. Re-run /quad."
else
  # Check if there's an active batch
  BATCH_STATE=$(curl -s "http://127.0.0.1:8400/api/projects/$PROJ/state" 2>/dev/null | python3 -c "import json,sys; d=json.loads(sys.stdin.read() or '{}'); print(d.get('batch','idle'))" 2>/dev/null)
  if [ "$BATCH_STATE" = "active" ] || [ "$BATCH_STATE" = "running" ]; then
    echo "NEXT: batch active — watch PRs land on https://github.com/.../pulls"
  else
    echo "NEXT: in dashboard chat, type '@head start a batch for <description>' + click Start Trigger."
  fi
fi
```

### Step 6 (only if `/quad` picked up pin-fix or trust changes) — Tell User to Reset Agents

If Step 3 or Step 4 made changes, the running claude/codex processes in the agent terminals are stale. Tell Zaal to click **Reset Agents** in the dashboard SERVER panel so they respawn with fresh state. Otherwise they'll still be waiting on old trust prompts.

## Overrides (Rare)

These exist but Zaal shouldn't need them day-to-day.

| Override | What |
|---|---|
| `/quad stop` | Kill server + AC (emergency stop) |
| `/quad open` | Just open the dashboard URL |

If Zaal asks for anything else (`fix-pin`, `trust`, `doctor`, `start`) — tell him: "Just run `/quad` — it auto-detects and does the right thing." The decision tree covers all the old sub-commands.

## Canonical Role Config

| Slot | CLI | Auth |
|---|---|---|
| Head | `claude` | Max sub |
| Dev | `claude` | Max sub |
| Reviewer 1 | `codex` (fallback: `claude`) | ChatGPT Plus/Pro (fallback: Max sub) |
| Reviewer 2 | `claude` | Max sub |

Cross-frontier on RE1 catches what Claude misses (Walden doc 479). All-claude fallback works if Codex not set up — loses model-diversity bias but keeps clean-context bias.

## Adding A New Project

No sub-command. Flow:

1. Zaal creates the GitHub repo + clones locally.
2. Zaal drops a `.quadwork-allowlist` in the repo (see template below) and a short `CLAUDE.md` telling agents to read it.
3. Zaal opens `http://127.0.0.1:8400/setup` in browser → fills the 4 fields → saves.
4. Zaal runs `/quad <new-project-id>` — decision tree fires, trusts worktrees, everything green.

### `.quadwork-allowlist` template

```
# Touchable paths (one glob per line)
src/**
docs/**
tests/**
README.md

# OFF LIMITS (agents must ignore):
# .env*
# secrets/**
# .github/workflows/**
# package.json
```

### Per-repo `CLAUDE.md` seed

```markdown
# <project name>

Before any Edit/Write, read `.quadwork-allowlist` and only touch paths that match.
If a task requires a path outside the allowlist, halt and ask the operator.
Never write secrets, API keys, private keys, or credentials.
```

## Safety Rails (Always Enforced)

1. **Branch protection on `main`** — 2 reviewer approval, linear history, no force push. Needs GitHub Pro on private repos ($4/mo).
2. **Allowlist first** — every project gets `.quadwork-allowlist` + CLAUDE.md rule before first batch.
3. **No secrets in worktrees** — `grep -rE '(sk-ant-|sk-|ghp_|PRIVATE_KEY)' ~/.quadwork/<project-id>/` must return zero matches.
4. **First 2 weeks = manual merge** — keep `auto_continue_loop_guard: false` until 3 batches land clean.
5. **Audit before trust** — the decision tree fails closed: if a worktree is missing `.git`, trust step is skipped.

## Reference

- Dashboard: `http://127.0.0.1:8400`
- Setup page: `http://127.0.0.1:8400/setup`
- Global config: `~/.quadwork/config.json`
- Per-project: `~/.quadwork/<project-id>/`
- Trust registry: `~/.claude.json` → `projects.<path>.hasTrustDialogAccepted`
- AgentChattr: `https://github.com/bcurts/agentchattr` (pinned)
- QuadWork: `https://github.com/realproject7/quadwork`
- Research: doc 487 (eval), doc 491 (install), doc 492 (pin bug), doc 479 (multi-agent principles)

## When to NOT Use QuadWork

Per doc 491: SKIP on zao-os. Don't point QuadWork at any repo where files under `src/app/api/`, `src/lib/auth/`, `src/lib/agents/`, `contracts/`, or schema migrations are in scope. Use it for: docs, tests, isolated refactors, new brand/bot repos (zao-chat, zao-brain when they exist), experimental sandboxes.
