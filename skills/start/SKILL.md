---
name: start
version: 1.0.0
description: |
  Start a tracked work session. Records start time, piece info, and description
  to a session-state file. Pairs with /end which calculates duration, appends
  a row to the hours log CSV, and drafts a Cameron update message.
  Default client: Riverside Group (Cameron). Hours log lives at
  /Users/zaalpanthaki/Documents/BetterCallZaal/Maine/Cameron/deliverables/wave-0-hours-log/hours-log.csv
allowed-tools:
  - Bash
  - Read
  - Write
  - AskUserQuestion
---

## Instructions

You are the hours-log session-starter. When invoked, capture what Zaal is about to work on and write a session-state file. The matching `/end` skill closes the session and logs the row.

### Step 1 - Check for active session

If `~/.claude/state/active-hours-session.json` exists, there is already an open session. Read it and ask Zaal:

- Was this an oversight? Offer to `/end` the prior session first.
- Did Zaal forget to end the last one? Offer to discard it (delete state file) and start fresh.
- Is this a different concurrent task? Warn that the model only supports one open session at a time.

Do NOT silently overwrite an open session.

### Step 2 - Gather inputs

Required inputs:

- **Piece number** (1-16 from the zaal page, OR "-" for cross-cutting / non-piece work)
- **Wave** (0-7, auto-inferable from the piece; if unclear, ask)
- **Short description** of what's about to be worked on (one sentence)
- **Piece name** (matches the zaal page; if piece # is "-" use a custom name)

Piece-to-wave + name mapping for Riverside (use this to auto-fill instead of asking when possible):

| Piece # | Wave | Name |
|---|---|---|
| 1 | 5 | Tool & inventory tracking |
| 2 | 3 | Daily log + shared updates |
| 3 | 2 | Website refresh |
| 4 | 1 | New logo + merch pack |
| 5 | 4 | Client intake + work orders |
| 6 | 7 | Advertising - clients & hiring |
| 7 | 5 | Equipment maintenance schedules |
| 8 | 4 | Budgets, POs, profit per job |
| 9 | 6 | Business phone + call routing |
| 10 | 6 | Insurance, COIs, compliance |
| 11 | 6 | Books + financial integration |
| 12 | 7 | Client communication & updates |
| 13 | 7 | Document & contract library |
| 14 | 1 | Materials cost sheet + estimating |
| 15 | 1 | Facebook business page |
| 16 | 1 | Ad creative system |
| - | 0 | Trust layer / hours log / setup |

If args were passed to /start, parse them. Otherwise use AskUserQuestion to gather missing fields. Args may look like:

- `/start 14 drafting starter SKU list from Hammond catalog`
- `/start 15` (then ask for description)
- `/start` (ask everything)

### Step 3 - Capture start time

Run:

```bash
START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LOCAL_TIME=$(date "+%Y-%m-%d %H:%M %Z")
```

Use the UTC timestamp for math, the local one for display.

### Step 4 - Write session state file

Write `~/.claude/state/active-hours-session.json` with this shape:

```json
{
  "client": "riverside",
  "piece": 14,
  "piece_name": "Materials cost sheet + estimating",
  "wave": 1,
  "description": "drafting starter SKU list from Hammond catalog",
  "start_time": "2026-05-15T18:32:18Z",
  "local_start": "2026-05-15 14:32 EDT",
  "log_file": "/Users/zaalpanthaki/Documents/BetterCallZaal/Maine/Cameron/deliverables/wave-0-hours-log/hours-log.csv"
}
```

Use the Write tool, not echo/cat.

### Step 5 - Confirm

Reply with one-line confirmation:

```
Started: Wave 1, Piece 14 (Materials cost sheet). Clock running since 14:32 EDT.
Run /end when done.
```

Keep it terse. Do not narrate. Do not explain. Done.

## Edge cases

- **No piece number passed and Zaal cannot recall:** suggest piece "-" wave 0 with a description like "cross-cutting work" so the session is still logged. Better to record loose than skip.
- **Hours log CSV does not exist yet:** that is fine, /end will create it from header row. Do not create here.
- **Active session is over 8 hours old:** warn before starting new. May be a forgotten /end from yesterday.
