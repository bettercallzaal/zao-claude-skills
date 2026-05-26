---
name: fetch
description: ZAO universal URL fetcher — picks the right tool per URL when WebFetch is blocked. Routes Reddit URLs to zao-fetch-reddit.sh (curl + Mozilla UA + .json), X/Twitter URLs to zao-fetch-x.sh (syndication endpoint + nitter + wayback fallback), HN to Algolia API, GitHub to gh CLI, others to WebFetch. Use when WebFetch returns a block message, when researching social-media content, or when the user shares a Reddit/X URL.
allowed-tools: Bash, Read, WebFetch, WebSearch
argument-hint: "<url>"
---

# /fetch - Universal URL Fetcher (Anti-Block Layer)

Routes URLs to the right scraping tool based on host. Patched 2026-04-29 per Doc 562 to handle WebFetch blocks on `reddit.com` + `x.com`.

## Decision Tree

Inspect the URL's host:

| Host pattern | Route to |
|---|---|
| `reddit.com`, `www.reddit.com`, `old.reddit.com`, `redd.it` | `~/bin/zao-fetch-reddit.sh "$URL"` |
| `x.com`, `twitter.com`, `mobile.twitter.com`, `vxtwitter.com`, `fxtwitter.com` | `~/bin/zao-fetch-x.sh "$URL"` |
| `news.ycombinator.com` items | `WebFetch` direct (works); or `https://hn.algolia.com/api/v1/items/<id>` |
| `github.com` | `gh api` CLI |
| `youtube.com`, `youtu.be` | Try `WebFetch` first; fall back to `yt-dlp --write-auto-sub --skip-download` if installed |
| Any HTTP 402 / "unable to fetch" from `WebFetch` | Try `Bash: curl -sSL -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"` |
| Anything else | `WebFetch` |

## How To Use

```
/fetch https://www.reddit.com/r/ClaudeCode/comments/1sy4137/...
/fetch https://x.com/shannholmberg/status/2038636871270424794
/fetch https://news.ycombinator.com/item?id=42000000
/fetch https://github.com/owner/repo
```

## Implementation

When invoked with `$ARGUMENTS` containing a URL:

### Step 1 - Parse the URL

Extract the host. Match against the table above.

### Step 2 - Reddit branch

```bash
~/bin/zao-fetch-reddit.sh "<url>"
```

Output is JSON. Parse with python or `jq`. For thread metadata + selftext + top comments:

```python
import json, sys
data = json.load(sys.stdin)
post = data[0]['data']['children'][0]['data']
print('TITLE:', post['title'])
print('AUTHOR: u/' + post['author'])
print('SCORE:', post['score'], 'COMMENTS:', post['num_comments'])
print('SELFTEXT:', post['selftext'][:3000])
for c in data[1]['data']['children'][:5]:
    cd = c['data']
    if cd.get('author'):
        print(f"u/{cd['author']} ({cd['score']} pts): {cd.get('body','')[:300]}")
```

For subreddit listings: `~/bin/zao-fetch-reddit.sh "r/SUB" "top" "10"`.

### Step 3 - X branch

```bash
~/bin/zao-fetch-x.sh "<url-or-id>"
```

Three-tier internal fallback:
1. `cdn.syndication.twimg.com/tweet-result?id=ID&token=4` (works for ~95% of public tweets)
2. `nitter.net/i/status/ID` (HTML scrape; reliable backup — only mirror still alive in May 2026)
3. `web.archive.org` snapshot (last-resort)

Output is human-readable summary + key fields + truncated JSON. For full data, modify the script to dump full JSON.

### Step 3b - X Article branch (v2, doc 660)

If the tweet wraps an X Article (URL form `/i/article/<id>`), the fetcher emits:

```
=== ARTICLE_DETECTED ===
ARTICLE_TITLE: ...
ARTICLE_PREVIEW: ... (first ~500 chars only)
ARTICLE_AUTHOR: <handle>
!! Body NOT in syndication payload - needs mirror search.
```

X Article bodies are NOT directly fetchable without a logged-in session (HTTP 402 paywall). No-login route is **author-mirror discovery**:

1. **Re-run with --mirrors flag** to get likely cross-post URLs:
   ```bash
   ~/bin/zao-fetch-x.sh --mirrors <tweet-id>
   ```
   This emits candidate URLs for: LinkedIn Pulse, Medium, Substack, paragraph.com, mirror.xyz, author's personal domain (3 slug variants).

2. **WebFetch each candidate** until one returns the full body. LinkedIn Pulse is the most common hit for business/tech writers (Aroussi case = success). Web3 authors more often cross-post to Mirror or Paragraph.

3. **If no mirror found**, fall back to **multi-snippet harvest**:
   - Take 3-5 distinctive phrases from `ARTICLE_PREVIEW`.
   - For each phrase, run a quoted-phrase WebSearch.
   - Concatenate the snippet matches into a partial reconstruction.
   - Always flag the doc as "premium-content reconstruction, not verbatim."

4. **Never claim verbatim quotes** unless a mirror was found. The preview text in the syndication payload IS verbatim and can be quoted; everything else from snippets is inferred.

5. **If the article body is critical to the doc**, the only login-free degradation path is: keep the preview + author context + flag the limitation; don't fabricate body content. Per `feedback_never_accept_pasted_secrets.md`, do NOT ask Zaal for X auth_token or login credentials.

### Step 4 - HN branch

WebFetch usually works on HN, but if blocked:

```bash
ID=$(echo "$URL" | grep -oE 'id=[0-9]+' | grep -oE '[0-9]+')
curl -sSL "https://hn.algolia.com/api/v1/items/$ID" | python3 -m json.tool
```

### Step 5 - GitHub branch

```bash
# Repo metadata
gh api "repos/$OWNER/$REPO"
# File contents
gh api "repos/$OWNER/$REPO/contents/PATH" --jq '.content' | base64 -d
# Issues / PRs
gh issue view N
gh pr view N
```

For raw file fetches that don't need auth: `https://raw.githubusercontent.com/OWNER/REPO/BRANCH/PATH` works with WebFetch.

### Step 6 - Generic fallback chain

If the URL doesn't match any branch above:

1. Try `WebFetch` directly.
2. If WebFetch returns "unable to fetch" or HTTP 4xx, try:
   ```bash
   curl -sSL -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36" --max-time 15 "<url>"
   ```
3. If still blocked, try `web.archive.org/web/2026/<url>`.
4. If still blocked, search-for-content via `WebSearch` (find a quoted snippet of the page elsewhere).

## Failure Modes

| Symptom | Recovery |
|---|---|
| Reddit: 429 (rate limited) | `zao-fetch-reddit.sh` exits 2; wait 10-15s; retry |
| Reddit: 403 (deeper block) | Try `last30days-skill` if installed - it has full Reddit auth flow |
| X: tombstone (deleted/private) | `zao-fetch-x.sh` reports "TOMBSTONE / ERROR"; use `last30days-skill` with browser session token |
| X: tier 1+2+3 all fail | Search via `WebSearch` for tweet text fragments; check if account is private |
| X Article body needed but no mirror exists | Stop. Preview + author context only. Flag doc as reconstruction. Do NOT request login credentials. (Doc 660) |
| Wayback rate limit | Wait 5 min; or use `archive.is` instead |

## Cross-References

- Doc 562 - Reddit/X scraping meta-eval + last30days-skill install (v1 baseline)
- Doc 660 - X content extraction v2: article detection + mirror discovery chain (2026-05-17)
- `~/bin/zao-fetch-reddit.sh` - Reddit fetcher source
- `~/bin/zao-fetch-x.sh` - X fetcher source (v2: 3-tier + article-detect + --mirrors flag)
- `last30days-skill` (installed at `~/.claude/skills/last30days/`) - canonical multi-source for breadth
- `reddit-fetch` skill (installed at `~/.claude/skills/reddit-fetch/`) - alternative Reddit pattern (Gemini CLI route)

## Notes For The Caller

- Be polite: max 1 fetch per 2 seconds for Reddit, 1 per 1 sec for X syndication
- Cache aggressively: same URL within a session = reuse result
- Surface first 200-300 chars of any error to the user, not just the exit code
- For research-tier work that needs MULTIPLE platforms (Reddit + X + HN + YouTube + ...), invoke `last30days-skill` instead of looping `/fetch` per URL
