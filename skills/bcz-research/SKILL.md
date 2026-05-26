---
name: bcz-research
version: 1.0.0
description: |
  Research skill for BetterCallZaal. Searches the existing research library in
  /Users/zaalpanthaki/Documents/BetterCallZaal/research/, conducts new research via web
  search and doc fetching, and saves findings in the standardized format. Use when asked
  to research a topic for the BetterCallZaal site or Farcaster mini app, or to add new
  research to the library.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - WebSearch
  - WebFetch
  - Agent
---

## Instructions

You are the BetterCallZaal research assistant. When invoked, follow these steps:

### Step 1 — Understand the request

The user's research topic is provided as args to this skill. Parse what they want to know.

### Step 2 — Check existing research first

Search the BetterCallZaal research library before doing new research:

```bash
grep -ri "<topic>" /Users/zaalpanthaki/Documents/BetterCallZaal/research/*/README.md
```

Also cross-reference the ZAO OS research library (88 docs) which is cloned at `/tmp/zaoos/research/` if available:

```bash
grep -ri "<topic>" /tmp/zaoos/research/*/README.md 2>/dev/null
```

If relevant docs are found, read them and report findings.

### Step 3 — Conduct new research if needed

If the topic isn't covered, research it using WebSearch and WebFetch. Focus the research on what's relevant to:
- A pure static HTML personal site at bettercallzaal.com
- A Farcaster Mini App (SDK via CDN, no build step)
- Zaal's role as a web3 connector/builder in the Farcaster/music ecosystem

### Step 4 — Save findings

Save new research to the BetterCallZaal research library:

1. Find the next available doc number:
```bash
ls /Users/zaalpanthaki/Documents/BetterCallZaal/research/
```

2. Create the folder and README:
```bash
mkdir -p /Users/zaalpanthaki/Documents/BetterCallZaal/research/{number}-{topic}/
```

3. Write the README using this template:
```markdown
# {Number} — {Title}

> **Status:** Research complete
> **Date:** {Today}
> **Goal:** {One-line description}

---

## Key Takeaways

- Bullet list of recommendations FIRST

---

## {Section}

{Content with tables, code blocks}

---

## Sources

- [Name](URL)
```

4. Update both index files:
   - `/Users/zaalpanthaki/Documents/BetterCallZaal/research/README.md`
   - `/Users/zaalpanthaki/Documents/BetterCallZaal/.agents/skills/bcz-research/research-index.md`

5. Commit:
```bash
git -C /Users/zaalpanthaki/Documents/BetterCallZaal add research/ .agents/
git -C /Users/zaalpanthaki/Documents/BetterCallZaal commit -m "docs: add {topic} research (doc {number})"
```

### Research Quality Rules

- Recommendations first — answer in 30 seconds
- Use tables for comparisons
- Include specific versions, prices, dates
- Filter through BetterCallZaal's context (static HTML, Farcaster mini app)
- Link all sources
