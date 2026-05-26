---
name: end
version: 1.0.0
description: |
  End a tracked work session started with /start. Calculates duration,
  appends a row to the hours-log CSV (in BOTH the internal repo + the
  deployed riverside-site so Cameron sees latest at /hours-log/), drafts
  a Cameron update message, copies it to the clipboard, and clears the
  session-state file.
  Default client: Riverside Group (Cameron).
  Hours log canonical CSV:
    /Users/zaalpanthaki/Documents/BetterCallZaal/Maine/Cameron/deliverables/wave-0-hours-log/hours-log.csv
  Deploy-mirrored CSV (read by /hours-log/ web page):
    /Users/zaalpanthaki/Documents/BetterCallZaal/Maine/Cameron/riverside-site/hours-log/data.csv
  Both must stay in sync. Live page: https://riverside-group-demo.vercel.app/hours-log/
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
---

## Instructions

You are the hours-log session-closer. When invoked, close the active session and produce two outputs: a logged CSV row, and a drafted Cameron update message in the clipboard.

### Step 1 - Read active session state

```bash
test -f ~/.claude/state/active-hours-session.json || echo "no-session"
```

If no session file: tell Zaal there is no active session. Ask if they want to log a manual entry (collect start time + duration + everything else). Do NOT pretend a session was running.

If session file exists: Read it. Parse client, piece, wave, piece_name, description, start_time.

### Step 2 - Calculate duration

```bash
START_TIME=$(jq -r .start_time ~/.claude/state/active-hours-session.json)
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Compute elapsed seconds, then hours rounded to nearest 0.25
START_SEC=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$START_TIME" "+%s" 2>/dev/null || date -d "$START_TIME" "+%s")
NOW_SEC=$(date -u "+%s")
ELAPSED_SEC=$((NOW_SEC - START_SEC))
# Hours = elapsed / 3600, round to nearest 0.25
HOURS=$(awk -v s=$ELAPSED_SEC 'BEGIN { h = s / 3600; printf "%.2f", int(h * 4 + 0.5) / 4 }')
```

If duration < 0.25 hr (< 15 min): warn. Ask Zaal if they want to log it as 0.25 or skip. Tiny sessions are usually accidental.

If duration > 6 hr: warn. Likely a forgotten /end. Ask Zaal to confirm or override with a manual hours value.

### Step 3 - Collect close-out info

Use AskUserQuestion to gather (or accept inline args):

- **What shipped** (one sentence, concrete - "Drafted 28 SKUs across mulch/loam/sheetrock/hardware categories with cost columns")
- **Artifact link** (Google Drive link to the file, GitHub link, design link - whatever points to the output)
- **Status** (in-progress | demo-ready | live | shelved). Default to `in-progress` if Zaal cannot decide; he can edit later in the Sheet. Status is project state only - ALL logged hours bill at $40/hr regardless.

If args were passed inline (e.g., `/end "drafted 28 SKUs" https://docs.google.com/... demo-ready`), parse them. Otherwise prompt.

### Step 4 - Append CSV row to BOTH log files

Construct the row:

```
DATE,WAVE,PIECE,PIECE_NAME,HOURS,WHAT_SHIPPED,ARTIFACT_LINK,STATUS,CAMERON_NOTE
2026-05-15,1,14,Materials cost sheet + estimating,1.50,"Drafted 28 SKUs across mulch/loam/sheetrock/hardware",https://docs.google.com/...,in-progress,
```

Escape commas in fields (wrap in double-quotes if the field contains comma or quote).

Check if the CSV files exist. If not, create with header row first:

```
Date,Wave,Piece #,Piece Name,Hours,What Shipped,Artifact Link,Status,Cameron Note
```

Append the row to BOTH paths (they must stay in sync):

1. `/Users/zaalpanthaki/Documents/BetterCallZaal/Maine/Cameron/deliverables/wave-0-hours-log/hours-log.csv` (canonical, in riverside-internal repo)
2. `/Users/zaalpanthaki/Documents/BetterCallZaal/Maine/Cameron/riverside-site/hours-log/data.csv` (deployed to Vercel - what Cameron sees)

After appending, optionally git-commit + push the riverside-site change so Cameron's /hours-log/ page shows the new row. Suggest the command, do not auto-push:

```
cd /Users/zaalpanthaki/Documents/BetterCallZaal/Maine/Cameron/riverside-site
git add hours-log/data.csv
git commit -m "hours-log: log session <date> piece <piece>"
git push archive ws/capabilities-deep-dive
vercel --prod --yes
```

### Step 5 - Draft Cameron message

Compose a natural, terse update. NOT a bot template. Match Zaal's actual voice: lowercase, no greetings, real sentences, no signoff.

Format (illustrative, adapt to the actual data):

```
quick update — spent {HOURS} hr today on {PIECE_NAME} (piece {PIECE}/16, wave {WAVE}).

{WHAT_SHIPPED}.

{ARTIFACT_LINK}

status: {STATUS}.{IF_IN_PROGRESS: " next session will [pick one logical next step from context]."}{IF_DEMO_READY: " ready for you to look at when you have a sec."}
```

Examples by status:

- **in-progress:** "quick update — spent 1.5 hr today on materials cost sheet (piece 14/16, wave 1). drafted 28 SKUs across mulch / loam / sheetrock / hardware categories with cost + unit columns. [link]. status: in-progress. next session will fill in your top stone yard + nursery once you send those names over."
- **demo-ready:** "quick update — spent 2.25 hr today on ad template v0 (piece 16/16, wave 1). built the before/after template in figma + dropped in real Riverside photos from the [job name]. [link]. status: demo-ready. ready for you to look at when you have a sec."
- **live:** rare from a single session — usually only after Cameron has reviewed. If `/end status=live`, the message should say "logged and shipped - this one's part of the system now."

### Step 6 - Copy to clipboard

```bash
echo "$MESSAGE" | pbcopy
```

If pbcopy fails (rare on macOS), print the message and tell Zaal to copy manually.

### Step 7 - Clear state file

```bash
rm ~/.claude/state/active-hours-session.json
```

### Step 8 - Confirm

Reply with:

```
Logged {HOURS} hr on piece {PIECE} ({PIECE_NAME}).
Row appended to: {CSV_PATH}
Cameron message drafted + copied to clipboard.

[show the message inline so Zaal can review before sending]

Don't forget to paste the new row into the shared Google Sheet.
```

Keep it terse. The message itself is the main output.

## Edge cases

- **Status = shelved:** This usually happens at Cameron's prompt, not Zaal's. If Zaal calls /end with shelved, log the row (hours still bill at $40/hr - flex employee) but tone the Cameron message as "piece shelved per your call, hours logged for the work done". Keep it neutral.
- **Cameron message turning generic:** If Zaal calls /end three times in a row with similar info, vary the phrasing. Do not repeat "quick update" verbatim every time.
- **Multiple pieces touched in one session:** Ask Zaal which one to log under (the dominant one), or whether to split into two manual rows.
- **CSV header drift:** If the existing header row in the CSV does not match the 9 columns above, do NOT silently rewrite. Flag and ask Zaal.
