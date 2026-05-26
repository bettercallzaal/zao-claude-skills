#!/usr/bin/env bash
# zao-skills-postedit-hook.sh - PostToolUse hook on Edit/Write.
#
# When a file under ~/.claude/skills/<skill>/ is edited, auto-sync that skill
# to the ~/dev/zao-claude-skills/ repo, commit, and push. No-op for any other path.
#
# Wired from ~/.claude/settings.json:
#   {
#     "PostToolUse": [
#       {
#         "matcher": "Edit|Write",
#         "hooks": [{
#           "type": "command",
#           "command": "FILE=\"$CLAUDE_TOOL_INPUT_file_path\" \"$HOME/bin/zao-skills-postedit-hook.sh\"",
#           "timeout": 30
#         }]
#       }
#     ]
#   }
#
# Best-effort: never abort the calling tool. All errors logged + swallowed.

set -u

LOG="$HOME/.zao/skill-sync.log"
mkdir -p "$(dirname "$LOG")"

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >> "$LOG"
}

FILE="${FILE:-${CLAUDE_TOOL_INPUT_file_path:-}}"

# 1. Bail unless the file is in ~/.claude/skills/<skill>/
case "$FILE" in
  "$HOME/.claude/skills/"*) ;;
  *) exit 0 ;;
esac

# 2. Extract the <skill> name (first path component under skills/)
REL="${FILE#$HOME/.claude/skills/}"
SKILL="${REL%%/*}"

if [ -z "$SKILL" ]; then
  log "no skill name extracted from $FILE - bail"
  exit 0
fi

# 3. Vendored skills (have .git/) are not synced
if [ -d "$HOME/.claude/skills/$SKILL/.git" ]; then
  log "$SKILL is vendored (has .git) - skipping auto-sync"
  exit 0
fi

REPO_DIR="$HOME/dev/zao-claude-skills"
if [ ! -d "$REPO_DIR/.git" ]; then
  log "repo $REPO_DIR not found - skipping auto-sync"
  exit 0
fi

# 4. Run the sync + auto-commit + push, but throttle - if a commit happened in
# the last 30 seconds for this same skill, skip (avoids edit-storm spam).
THROTTLE_FILE="$HOME/.zao/.skill-sync-last-$SKILL"
NOW=$(date +%s)
if [ -f "$THROTTLE_FILE" ]; then
  LAST=$(cat "$THROTTLE_FILE" 2>/dev/null || echo 0)
  if [ $((NOW - LAST)) -lt 30 ]; then
    log "$SKILL - throttled ($(( NOW - LAST ))s ago); will resync on next edit after 30s"
    exit 0
  fi
fi

# 5. Sync the one skill
if ! "$HOME/bin/zao-skills-sync" push "$SKILL" >> "$LOG" 2>&1; then
  log "push to repo failed for $SKILL"
  exit 0
fi

# 6. Commit + push if there are changes
cd "$REPO_DIR" || { log "cd $REPO_DIR failed"; exit 0; }

if ! git diff --quiet --exit-code "skills/$SKILL/" 2>/dev/null || \
   git status --porcelain "skills/$SKILL/" 2>/dev/null | grep -q .; then

  git add "skills/$SKILL/" >> "$LOG" 2>&1
  if git diff --cached --quiet --exit-code 2>/dev/null; then
    log "$SKILL - no actual diff staged, skipping"
    exit 0
  fi

  MSG="auto-sync: $SKILL ($(basename "$FILE"))"
  if git commit -m "$MSG" --no-verify >> "$LOG" 2>&1; then
    log "$SKILL - committed"
    if git push >> "$LOG" 2>&1; then
      log "$SKILL - pushed"
      echo "$NOW" > "$THROTTLE_FILE"
    else
      log "$SKILL - push failed (committed locally, retry next time)"
    fi
  else
    log "$SKILL - commit failed"
  fi
else
  log "$SKILL - no diff after rsync"
fi

exit 0
