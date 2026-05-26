#!/usr/bin/env bash
# clipboard-emit.sh - write a clipboard page + update the history index + open it.
#
# Each /clipboard call writes a timestamped HTML file at
# ~/.zao/clipboard/clip-<ts>-<slug>.html, copies it to /tmp/clipboard.html
# (the back-compat default `open` opens), and regenerates the index of all
# saved clips so you can scroll back through prior pastes.
#
# Usage:
#   echo "$BODY_HTML" | clipboard-emit.sh <title> <slug>
#
# Where:
#   - title = human-readable header (max ~60 chars)
#   - slug  = filename-safe identifier (kebab-case, no spaces)
#   - BODY_HTML = the inner <div class="content"> markup, on stdin
#
# Caller is expected to have already HTML-escaped the body and applied any
# `<h2>` / `<strong>` formatting. This script wraps it in the standard
# template (header bar, copy button, toast, nav back to index).
#
# Auto-prunes anything older than the newest 50 clips.

set -uo pipefail

TITLE="${1:-Clipboard}"
SLUG="${2:-clip}"

HOME_DIR="$HOME/.zao/clipboard"
mkdir -p "$HOME_DIR"

# Read body from stdin (whole file).
BODY=$(cat)
if [[ -z "$BODY" ]]; then
  echo "ERROR: empty body on stdin" >&2
  exit 2
fi

TS=$(date +%Y%m%d-%H%M%S)
SLUG_CLEAN=$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9-]+/-/g; s/^-+|-+$//g' | cut -c1-50)
CLIP_FILE="$HOME_DIR/clip-${TS}-${SLUG_CLEAN}.html"

# Escape TITLE for HTML attribute / text contexts. Body is caller-trusted.
ESC_TITLE=$(printf '%s' "$TITLE" | python3 -c 'import sys, html; print(html.escape(sys.stdin.read()), end="")' 2>/dev/null || printf '%s' "$TITLE")

cat > "$CLIP_FILE" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>$ESC_TITLE</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    background: #0a1628; color: #e2e8f0; padding: 20px; line-height: 1.55; }
  .container { max-width: 760px; margin: 0 auto; }
  .navbar { display: flex; gap: 10px; align-items: center; font-size: 11px;
    color: rgba(255,255,255,0.45); margin-bottom: 12px; padding-bottom: 8px;
    border-bottom: 1px solid rgba(255,255,255,0.06); }
  .navbar a { color: #f5a623; text-decoration: none; }
  .navbar a:hover { color: #ffd700; }
  .header { display: flex; justify-content: space-between; align-items: center;
    margin-bottom: 18px; padding-bottom: 12px; border-bottom: 1px solid rgba(255,255,255,0.08); }
  .header h1 { font-size: 16px; color: #f5a623; flex: 1; padding-right: 12px; }
  .copy-btn { background: #f5a623; color: #000; border: none; padding: 9px 20px;
    border-radius: 8px; font-weight: 700; font-size: 13px; cursor: pointer;
    white-space: nowrap; }
  .copy-btn:hover { background: #ffd700; }
  .copy-btn.copied { background: #22c55e; color: #fff; }
  .content { background: #0d1b2a; border: 1px solid rgba(255,255,255,0.08);
    border-radius: 12px; padding: 22px; white-space: pre-wrap; font-size: 14px;
    cursor: text; user-select: text; }
  .content h2 { color: #f5a623; margin: 16px 0 6px; font-size: 14.5px; }
  .content h2:first-child { margin-top: 0; }
  .content strong { color: #fff; }
  .content pre, .content .snippet { background: #050d18;
    border: 1px solid rgba(245,166,35,0.18); border-radius: 8px; padding: 14px 16px;
    margin: 10px 0 14px; font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    font-size: 12.5px; line-height: 1.5; overflow-x: auto; position: relative;
    white-space: pre-wrap; word-break: break-word; }
  .snippet-wrap { position: relative; margin: 10px 0 14px; }
  .snippet-wrap pre, .snippet-wrap .snippet { margin: 0; padding-right: 86px; }
  .snippet-copy { position: absolute; top: 8px; right: 8px; background: rgba(245,166,35,0.15);
    color: #f5a623; border: 1px solid rgba(245,166,35,0.35); padding: 4px 10px;
    border-radius: 6px; font-size: 11px; font-weight: 600; cursor: pointer;
    font-family: -apple-system, sans-serif; }
  .snippet-copy:hover { background: rgba(245,166,35,0.25); }
  .snippet-copy.copied { background: #22c55e; color: #fff; border-color: #22c55e; }
  .toast { position: fixed; bottom: 24px; left: 50%;
    transform: translateX(-50%) translateY(100px); background: #22c55e; color: #fff;
    padding: 12px 24px; border-radius: 8px; font-weight: 600; font-size: 14px;
    transition: transform 0.3s ease; z-index: 100; }
  .toast.show { transform: translateX(-50%) translateY(0); }
</style>
</head>
<body>
<div class="container">
  <div class="navbar">
    <a href="file://$HOME_DIR/index.html">&larr; all clips</a>
    <span>&middot;</span>
    <span>saved $TS</span>
  </div>
  <div class="header">
    <h1>$ESC_TITLE</h1>
    <button class="copy-btn" onclick="copyAll()">Copy All</button>
  </div>
  <div class="content" id="content">$BODY</div>
</div>
<div class="toast" id="toast">Copied!</div>
<script>
function showToast(msg) {
  const t = document.getElementById('toast');
  t.textContent = msg || 'Copied!';
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 2000);
}
function copyText(text, btn, originalLabel) {
  navigator.clipboard.writeText(text).then(() => {
    if (btn) {
      btn.textContent = 'Copied!'; btn.classList.add('copied');
      setTimeout(() => { btn.textContent = originalLabel; btn.classList.remove('copied'); }, 2000);
    }
    showToast('Copied!');
  }).catch(() => {
    showToast('Copy blocked - select + Cmd+C');
  });
}
function copyAll() {
  const el = document.getElementById('content');
  const btn = document.querySelector('.copy-btn');
  copyText(el.innerText, btn, 'Copy All');
}
// Wrap every <pre> (or .snippet) in the content area with its own Copy button.
// Lets users grab just the snippet without the surrounding instructions.
(function attachSnippetCopyButtons() {
  const content = document.getElementById('content');
  if (!content) return;
  const targets = content.querySelectorAll('pre, .snippet');
  targets.forEach((node) => {
    if (node.dataset.copyAttached === '1') return;
    node.dataset.copyAttached = '1';
    const wrap = document.createElement('div');
    wrap.className = 'snippet-wrap';
    node.parentNode.insertBefore(wrap, node);
    wrap.appendChild(node);
    const btn = document.createElement('button');
    btn.className = 'snippet-copy';
    btn.type = 'button';
    btn.textContent = 'Copy';
    btn.addEventListener('click', () => copyText(node.innerText, btn, 'Copy'));
    wrap.appendChild(btn);
  });
})();
</script>
</body>
</html>
HTML

# Copy to /tmp for back-compat (`open /tmp/clipboard.html` still hits the latest).
cp "$CLIP_FILE" /tmp/clipboard.html

# Auto-prune: keep newest 50 clips, drop older.
# shellcheck disable=SC2012
ls -1t "$HOME_DIR"/clip-*.html 2>/dev/null | tail -n +51 | xargs rm -f 2>/dev/null || true

# Regenerate index.
INDEX="$HOME_DIR/index.html"
{
  cat <<'TOP'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Clipboard history</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    background: #0a1628; color: #e2e8f0; padding: 20px; line-height: 1.55; }
  .container { max-width: 760px; margin: 0 auto; }
  h1 { font-size: 17px; color: #f5a623; margin-bottom: 18px; padding-bottom: 12px;
    border-bottom: 1px solid rgba(255,255,255,0.08); }
  .clip { display: block; padding: 12px 14px; background: #0d1b2a;
    border: 1px solid rgba(255,255,255,0.08); border-radius: 8px;
    margin-bottom: 8px; text-decoration: none; color: inherit; transition: all 0.15s; }
  .clip:hover { border-color: rgba(245,166,35,0.4); background: #102234; }
  .clip-title { font-size: 14px; color: #fff; font-weight: 600; }
  .clip-meta { font-size: 11px; color: rgba(255,255,255,0.45); margin-top: 4px; }
  .footer { font-size: 11px; color: rgba(255,255,255,0.35); margin-top: 18px;
    padding-top: 12px; border-top: 1px solid rgba(255,255,255,0.06); }
</style>
</head>
<body>
<div class="container">
  <h1>Clipboard history</h1>
TOP

  for f in $(ls -1t "$HOME_DIR"/clip-*.html 2>/dev/null); do
    base=$(basename "$f")
    # base = clip-YYYYMMDD-HHMMSS-<slug>.html
    ts_date=$(echo "$base" | sed -E 's/^clip-([0-9]{8})-([0-9]{6})-.*\.html$/\1 \2/')
    yyyy=${ts_date:0:4}
    mm=${ts_date:4:2}
    dd=${ts_date:6:2}
    hh=${ts_date:9:2}
    mi=${ts_date:11:2}
    pretty_ts="${yyyy}-${mm}-${dd} ${hh}:${mi}"
    # title = pulled from <title> tag of the file
    page_title=$(grep -oE '<title>[^<]+</title>' "$f" | head -1 | sed -E 's/<\/?title>//g')
    [[ -z "$page_title" ]] && page_title="(no title)"
    slug=$(echo "$base" | sed -E 's/^clip-[0-9]{8}-[0-9]{6}-(.*)\.html$/\1/')
    cat <<CLIP
  <a class="clip" href="file://$f">
    <div class="clip-title">$page_title</div>
    <div class="clip-meta">$pretty_ts &middot; $slug</div>
  </a>
CLIP
  done

  cat <<'BOT'
  <div class="footer">Latest auto-opens via /tmp/clipboard.html. Older clips persist at ~/.zao/clipboard/ until the newest-50 prune.</div>
</div>
</body>
</html>
BOT
} > "$INDEX"

# Open the latest.
open "$CLIP_FILE" 2>/dev/null || open /tmp/clipboard.html
echo "OK saved $CLIP_FILE"
echo "    index $INDEX"
