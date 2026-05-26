---
name: clipboard
description: Open a clean local browser page with content ready to copy/paste or share. Every call also saves to ~/.zao/clipboard/ so prior pastes are browsable. Use when the user needs to copy text out of the terminal, share a summary, or send formatted content somewhere.
---

# Clipboard - Copy/Share from Browser, with history

Opens a clean local HTML page with content formatted and ready to copy with one click. Every call ALSO saves to `~/.zao/clipboard/` so the user can scroll back through prior pastes (Iman test plans, todo lists, announcement drafts, anything).

## How it works

1. Each /clipboard call writes `~/.zao/clipboard/clip-<YYYYMMDD-HHMMSS>-<slug>.html`.
2. Copies the latest to `/tmp/clipboard.html` (back-compat: `open /tmp/clipboard.html` still hits the most recent).
3. Regenerates `~/.zao/clipboard/index.html` listing every saved clip newest-first.
4. Auto-prunes anything older than the newest 50.
5. Opens the latest in the browser. Top of every page has a `← all clips` link back to the index.

## Usage

When invoked, check if there's content in the current conversation that the user wants to copy. If not, ask what they want on the clipboard page.

## Implementation

**Do NOT hand-roll the HTML each time.** Use the helper script at `~/.claude/skills/clipboard/bin/clipboard-emit.sh`.

It takes:
- `$1` = page title (human-readable, max ~60 chars, e.g. "Iman test plan for PR #11")
- `$2` = slug (kebab-case, e.g. "iman-pr-11-test")
- `stdin` = the inner content HTML (apply markdown transforms below first)

The script wraps your content in the standard template (dark UI, header bar with title, Copy All button, toast, nav back to the index, auto-prune).

### Pattern to follow

```bash
cat <<'BODY' | bash ~/.claude/skills/clipboard/bin/clipboard-emit.sh "Iman test plan for PR #11" "iman-pr-11-test"
<h2>Test 1 - Public homepage</h2>
1. Hard refresh in incognito.
2. Expect the landing page.

<h2>Test 2 - Security</h2>
Visit /chat in incognito - should redirect to /login.
BODY
```

After it runs:
- The new clip lives at `~/.zao/clipboard/clip-<ts>-iman-pr-11-test.html`.
- `/tmp/clipboard.html` is now a copy of it.
- The browser auto-opens to the new page.
- Click "all clips" in its header to see the history.

### Markdown to HTML conversion (apply before piping to the script)

The script does NOT transform markdown. Pre-transform the body:
- `**text**` -> `<strong>text</strong>`
- Lines starting with `## ` -> `<h2>text</h2>`
- Lines starting with `# ` -> skip (use the `$1` title instead)
- Lines starting with `- ` -> keep as-is (pre-wrap renders them fine)
- Empty lines -> blank lines (pre-wrap renders them)
- HTML-escape `<`, `>`, `&` in the content first

You can also just write HTML directly in the heredoc - the content div uses `white-space: pre-wrap` so plain text + `<h2>` / `<strong>` tags render right.

### Multi-section pages (multiple independent Copy buttons)

When the user wants several things in one page each independently copyable (4 platform drafts, Iman test plan + Vercel env steps, etc.), the helper isn't expressive enough. Write the HTML to `/tmp/clipboard.html` directly via Bash heredoc (the pre-upgrade pattern). Include a `<div class="navbar"><a href="file://$HOME/.zao/clipboard/index.html">← all clips</a></div>` so the user can still navigate back to history. Skip the helper for these.

The helper is for single-section pages where one Copy is the whole point.

### Telling the user

After invoking the helper or writing the page:
- One-liner: "Opened. Copy button at the top, history at `~/.zao/clipboard/index.html`."
- If they ask "where's the previous one" - point them at the index.

## Notes

- `~/.zao/clipboard/` persists across reboots; `/tmp/` does not.
- Prune is newest-50; older clips silently dropped.
- Index regenerates on every call so it always reflects current state.
- No secrets in clip content - if a clip would contain a password / key / token, refuse and tell the user to handle it outside the clipboard flow (per `feedback_never_accept_pasted_secrets`).
