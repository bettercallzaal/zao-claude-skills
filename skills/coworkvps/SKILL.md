---
name: coworkvps
description: SSH into Iman's Hostinger VPS (187.77.3.104) to manage the @ZAOcoworkingBot deployment (cowork-zaodevz/agent/). Wraps the common ops - status, logs, restart, deploy, env tweak. Use when asked to "check coworkvps", "/coworkvps", "ssh to cowork box", "deploy cowork bot", "tail cowork logs".
---

# /coworkvps - cowork-zaodevz VPS operator

SSH-based admin shortcuts for the **ZAOcoworkingBot** running on Iman's Hostinger VPS at `187.77.3.104` (NOT VPS 1 / 31.97.148.88 which is ZOE).

## Connection

- Host: `root@187.77.3.104`
- Key: `~/.ssh/id_ed25519` (do-openclaw, same key as VPS 1)
- Repo on VPS: `/root/cowork-zaodevz/` (clone of `songchaindao-dot/cowork-zaodevz`)
- Bot subpackage: `/root/cowork-zaodevz/agent/` (committed to repo, do NOT edit on VPS - PR through github)
- Runtime state: `/root/.zaocoworking/` (persona, human, recent/, archive/, actions.json cache, pending suggestions)
- Service: `zaocoworking-bot.service` (systemd user unit)

## Source-of-truth rule

**All bot code lives in github.com/songchaindao-dot/cowork-zaodevz under `agent/`.** The VPS only holds:
- the git clone (regenerable)
- node_modules (regenerable via `npm install`)
- agent/.env (secrets only - never commit)
- ~/.zaocoworking/ (runtime state - persona is hand-editable, the rest is bot-managed)

**Never edit `/root/cowork-zaodevz/agent/src/` on the VPS directly.** Always go through a PR. If you find yourself wanting to vim a file on the box, stop, push a PR, then deploy.

## Commands (what to do per intent)

### Status check (default `/coworkvps`)

```bash
ssh root@187.77.3.104 'echo "=== service ==="; systemctl --user is-active zaocoworking-bot.service; echo "=== uptime ==="; systemctl --user show zaocoworking-bot.service -p ActiveEnterTimestamp --value; echo "=== last 10 log ==="; journalctl --user -u zaocoworking-bot.service -n 10 --no-pager; echo "=== git state ==="; cd /root/cowork-zaodevz && git log --oneline -3 && git status -sb'
```

### Tail logs (`/coworkvps logs`)

```bash
ssh root@187.77.3.104 'journalctl --user -u zaocoworking-bot.service -f --no-pager'
```

(Use Monitor tool if running from Claude Code so notifications flow.)

### Restart (`/coworkvps restart`)

```bash
ssh root@187.77.3.104 'systemctl --user restart zaocoworking-bot.service && sleep 5 && systemctl --user is-active zaocoworking-bot.service && journalctl --user -u zaocoworking-bot.service --since "10 seconds ago" --no-pager | tail -10'
```

### Deploy a merged PR (`/coworkvps deploy`)

```bash
ssh root@187.77.3.104 'set -e
cd /root/cowork-zaodevz
git fetch origin
git checkout main 2>/dev/null || true
git pull --ff-only
cd agent
npm install
systemctl --user daemon-reload
systemctl --user restart zaocoworking-bot.service
sleep 5
systemctl --user is-active zaocoworking-bot.service
journalctl --user -u zaocoworking-bot.service --since "10 seconds ago" --no-pager | tail -10'
```

If npm install added/removed scripts that change the systemd `ExecStart`, also re-copy the unit:
```bash
ssh root@187.77.3.104 'cp /root/cowork-zaodevz/agent/systemd/zaocoworking-bot.service ~/.config/systemd/user/ && systemctl --user daemon-reload && systemctl --user restart zaocoworking-bot.service'
```

### Deploy a feature branch (pre-merge testing)

```bash
ssh root@187.77.3.104 'cd /root/cowork-zaodevz && git fetch origin && git checkout <BRANCH_NAME> && cd agent && npm install && systemctl --user restart zaocoworking-bot.service'
```

Use sparingly. Default = deploy from `main` after PR merge.

### Edit .env (`/coworkvps env`)

To add or rotate a secret:

```bash
# Pipe value via ssh stdin so it never lands in chat
echo "GITHUB_TOKEN=<value>" | ssh root@187.77.3.104 'cat >> /root/cowork-zaodevz/agent/.env && chmod 600 /root/cowork-zaodevz/agent/.env && grep -c "^GITHUB_TOKEN=" /root/cowork-zaodevz/agent/.env'
```

To replace a value, use a more careful one-liner. Don't echo secret values into chat or logs.

### Hand-edit persona (`/coworkvps persona`)

The persona is hand-editable and lives at runtime, NOT in the repo:

```bash
ssh -t root@187.77.3.104 'nano /root/.zaocoworking/persona.md && systemctl --user restart zaocoworking-bot.service'
```

(`-t` forces TTY for nano. Restart picks up the change.)

### Run a one-off command (`/coworkvps exec <cmd>`)

```bash
ssh root@187.77.3.104 '<cmd>'
```

### Tail today's transcript

```bash
ssh root@187.77.3.104 'date_iso=$(date -u +%Y-%m); ls /root/.zaocoworking/archive/ 2>/dev/null && echo "" && for d in /root/.zaocoworking/archive/*/; do echo "=== $(basename $d) ==="; tail -5 "$d/$date_iso.jsonl" 2>/dev/null | jq -r ".from_user_name + \": \" + .message_text" 2>/dev/null; done'
```

## Common ops cheat

| Intent | Command pattern |
|---|---|
| Is bot alive? | `ssh root@187.77.3.104 'systemctl --user is-active zaocoworking-bot.service'` |
| What ran last? | `ssh root@187.77.3.104 'journalctl --user -u zaocoworking-bot.service -n 20 --no-pager'` |
| Pull + restart after merge | `/coworkvps deploy` block above |
| Add a user to allowlist | edit `/root/cowork-zaodevz/agent/.env` `ALLOWLIST_USER_IDS=` and `USER_NAMES=`, then restart |
| Add a group | @mention bot in the group, grep journal for "drop from" log line to get chat ID, add to `ALLOWLIST_CHAT_IDS=`, restart |
| View actions cache | `ssh root@187.77.3.104 'jq . /root/.zaocoworking/actions.json | head -40'` |
| Clear pending suggestion (stuck confirm flow) | `ssh root@187.77.3.104 'rm /root/.zaocoworking/pending-suggestion.json'` |

## Failure-mode triage

| Symptom | Likely cause | Fix |
|---|---|---|
| `systemctl is-active` returns `failed` | crash on boot; check journalctl | tail logs, fix env or code, restart |
| `claude: command not found` in journal | `claude` not on systemd PATH | unit file's `Environment=PATH=` must include `/root/bin` or wherever `claude` lives |
| `tsx: command not found` | `npm install` was run with `--omit=dev` | re-run `npm install` (no flag) to restore tsx |
| 401 on Octokit calls | GITHUB_TOKEN expired/wrong | regenerate fine-grained PAT, pipe to .env, restart |
| 409 conflicts on every write | web app + bot racing | normal under load, SHA-dance retries 3x then errors back to user |
| Bot ignores allowlisted user | ALLOWLIST_USER_IDS format wrong (extra space, wrong separator) | check `grep ALLOWLIST /root/cowork-zaodevz/agent/.env` |
| Pending suggestion never clears | TTL is 5min, but file may persist | `rm /root/.zaocoworking/pending-suggestion.json` |

## Hard rules

1. **Code edits go through github PRs only.** Never `vim src/*.ts` on the VPS.
2. **Secrets never enter chat.** Use the `ssh ... stdin` pipe pattern for adding/rotating env values.
3. **Persona + human files are runtime hand-edits.** They live at `/root/.zaocoworking/persona.md` and `.../human.md`, NOT in the repo. Edit on the VPS; restart to apply.
4. **Backups before destructive ops.** Before `git reset --hard` or `rm -rf agent/`, ensure the v1.backup or equivalent exists.

## Spec sources

- Architecture: ZAOOS [doc 662](https://github.com/bettercallzaal/ZAOOS/tree/main/research/dev-workflows/662-zaocoworking-v2-v3-architecture)
- Bot repo: github.com/songchaindao-dot/cowork-zaodevz under `agent/`
- Memory: `project_zaocoworkingbot.md`, `project_iman_role.md`, `project_cowork_zaodevz.md`
