---
name: bcz-yapz-description
description: Render a BCZ YapZ YouTube description + tags from a transcript file. Input a transcript slug (e.g. `2026-04-22-dish-clanker` or `undated-deepa-grantorb`). Output is a paste-ready description body + tags written to /Users/zaalpanthaki/Documents/bcz-yapz/content/youtube-descriptions/ with the body copied to the macOS clipboard via pbcopy. Use when Zaal asks to generate, draft, or refresh a YouTube description for a BCZ YapZ episode.
---

# BCZ YapZ Description Skill

Generate a paste-ready YouTube description + tags for a BCZ YapZ episode from
its transcript file.

Spec: `/Users/zaalpanthaki/Documents/ZAO OS V1/research/dev-workflows/477-youtube-seo-bcz-yapz/README.md` (institutional memory, stays in ZAOOS)
Template: `content/templates/youtube-description.md`
Tags template: `content/templates/youtube-tags.txt`
Link map: `content/templates/link-map.json`
Gaps sidecar: `content/templates/link-map.gaps.md`

The project root is `/Users/zaalpanthaki/Documents/bcz-yapz`. All paths below
are relative to that root unless absolute.

NOTE: BCZ YapZ graduated out of the ZAO OS monorepo on 2026-05-06 into its own
repo at `github.com/bettercallzaal/bcz-yapz`. Always operate against
`/Users/zaalpanthaki/Documents/bcz-yapz/`. Do NOT touch the old paths under
`ZAO OS V1/content/transcripts/bcz-yapz/` etc - they were deleted during the
graduation.

## Inputs & Invocation

Invoked via `/bcz-yapz-description <transcript-slug>`.

The slug is the filename under `content/transcripts/` (in the bcz-yapz repo)
without the `.md` extension.

Examples:
- `/bcz-yapz-description 2026-04-22-dish-clanker`
- `/bcz-yapz-description 2026-04-14-nikoline-hubs-network`
- `/bcz-yapz-description undated-deepa-grantorb`

If no argument is passed, list available slugs via
`ls /Users/zaalpanthaki/Documents/bcz-yapz/content/transcripts/` and ask the
user which one.

## Step 1: Read + Parse Transcript

1. Read `/Users/zaalpanthaki/Documents/bcz-yapz/content/transcripts/<slug>.md`
   via the Read tool.
2. Split at the first `## Transcript` header (case-sensitive). Above = YAML
   frontmatter. Below = transcript body.
3. Parse the frontmatter in-prompt. Extract these fields:
   - `title`, `show`, `episode` (optional), `guest`, `guest_alias` (optional),
     `guest_org`, `guest_links` (array of `"platform: handle"` strings), `host`,
     `date` (ISO) or set to `null` if missing or filename starts with `undated-`,
     `published` (optional - overrides `date`), `duration_min`, `format`,
     `language`, `topics` (array), `keywords` (array),
     `entities.orgs`, `entities.people`, `entities.projects`, `summary`,
     `action_items`, `status`.
4. Normalize:
   - `guest_alias` defaults to the first whitespace-separated token of `guest`
     if not set.
   - `guest_slug` = lowercased, hyphenated `guest_alias`.
   - `date_display` = `date` or `published` as ISO; or `"TBD"` if both missing
     or filename starts with `undated-`.
   - `date_iso` = same ISO string or `null`.
   - For each `guest_links` entry, split on first `:` into
     `{platform, value}`. Trim both sides. Keep ordering.
5. Preserve the raw transcript body for Step 3.

## Data Fallbacks (missing / empty frontmatter fields)

Many older transcripts (especially `undated-*`) have empty or missing
fields. Handle each explicitly:

| Field | If missing/empty |
|-------|------------------|
| `summary` | Derive a 1-sentence summary from the first 500 chars of the transcript body (the intro section). Use that as the seed for P1 + `core_topic` + `summary_hook`. |
| `entities.orgs` / `.projects` / `.people` all empty or missing | Body-scan fallback: scan the transcript body for capitalized noun phrases that appear 2+ times AND match a key in `link-map.json`. Also always include `guest_org` as an org. Do NOT invent entities not present in the body. Extracted entities go through Step 2 URL resolution normally. |
| `entities.<category>` has some entries, others empty | Use what's there. Do NOT body-scan to fill a non-empty category. `guest_org` is always added to `entities.orgs` if not already present. |
| `topics` empty | Derive 4-8 lowercase-hyphenated topic tags from the summary + body (nouns like `grant-writing`, `ai-agents`, `solo-founder`). Used in tags line only. |
| `keywords` empty | Derive 5 long-tail lowercase-hyphenated keywords from body (specific named tools, platforms, tech). Used in tags line + hook. |
| `action_items` empty | Skip the near-term CTA sentence in P3. |
| `guest_links` empty or missing | Omit the entire `FOLLOW {{guest}}` block (header + body). Do NOT emit a `[Links to be filled]` placeholder or any stand-in text. |
| `date` and `published` both missing, OR filename starts with `undated-` | Set `date_display = "TBD"`, `date_iso = null`. Proceed normally. |
| `duration_min` missing | Use `max(timestamp_seconds) / 60` from the transcript body scan (Step 3.1) as the duration. |

If a body-scan fallback produces zero entities AND the transcript has no
`guest_org`, skip the `MENTIONED IN THIS EPISODE` block entirely (omit header
+ body), per Step 5.1 empty-handling rules.

## Step 2: Resolve Entity URLs via Link Map

1. Read `content/templates/link-map.json`.
2. For each entity in `entities.orgs`, `entities.projects`, `entities.people`:
   a. Normalize key: lowercase, trim whitespace.
   b. Look up in matching category map (`orgs` / `projects` / `people`).
   c. If found: attach `url = <value>`.
   d. If NOT found: attach `url = null` + add to in-memory `gaps` list with
      `(entity_name, category, source_slug)`.
3. After resolving, if `gaps` non-empty:
   a. Read `content/templates/link-map.gaps.md`.
   b. For each gap, append a bullet under `## Unresolved` in the format:
      `` - `<entity_name>` (first seen: <slug>, category: <orgs|projects|people>) ``
   c. Deduplicate - do NOT append if the same `(entity_name, category)` pair
      already appears in the file.
   d. If the existing content is `(empty)`, replace it with the new bullets.
   e. Write the updated file back via Edit/Write.
4. Do NOT block rendering on gaps. Unresolved entries render as
   `{Name}` (no URL) in the Mentioned block instead of `{Name} - <url>`.

## Step 3: Extract 10-15 Chapters from Transcript Body

Transcripts carry inline `[HH:MM:SS]` markers every few seconds. Pick 10-15
as YouTube chapter boundaries.

### 3.1 Scan + segment

1. Find every `[HH:MM:SS]` marker. Capture position + 200 surrounding chars of
   context.
2. Convert each to total seconds: `HH*3600 + MM*60 + SS`.
3. `duration_sec = max(timestamp_seconds)`.
4. Target chapter count = `clamp(round(duration_sec / 150), 10, 15)`. Hard
   bounds: floor 8, ceiling 18.

### 3.2 Candidate boundaries

Mark a timestamp as a chapter candidate if the following 200 chars contain ANY:

| Signal | Example phrase |
|--------|----------------|
| Named project/org/person from resolved entities | "so Clanker is", "Lorenzo from Nasha" |
| Zaal transition phrase | "let's talk about", "tell me about", "switching gears", "one last thing", "moving on to", "I wanted to ask you about" |
| Guest new story arc | "so I started", "originally I", "before I got into", "now we're building", "what's next" |
| Explicit topic question from Zaal | "why did you", "how does", "what is", "when did you" |

### 3.3 Reduce to target count

1. First chapter MUST be at `0:00` with title `Welcome + who is <guest_alias>`.
2. Last chapter MUST be in the last 3 minutes of the video with title
   `Outro + where to find <guest_alias>` (or use `action_items[0]` phrasing
   if it fits under 50 chars).
3. From remaining candidates, select `target_count - 2` by:
   a. Minimum gap 60 seconds between consecutive chapters.
   b. Prefer named-entity signals over transition phrases.
   c. If too few, relax transition-phrase threshold or insert time-based
      boundaries at even intervals.
4. Round each timestamp DOWN to the nearest 5-second mark:
   `seconds -= (seconds % 5)`.
5. Convert to display format: `mm:ss` if under 60 min, else `h:mm:ss`.
   Single-digit minutes OK (`2:45`). Seconds always 2-digit (`2:05` not `2:5`).

### 3.4 Title each chapter

Under 50 chars. Use actual project/person/org names from the surrounding 200
chars of context.

NEVER use: "Part 1", "Topic 2", "Discussion", "More on crypto".

Prefer specific noun phrases: "GameStop NFT era + getting into crypto",
"Capsule Social, Blogchain, Paris detour", "Launching Clanker on Farcaster".

If context ambiguous, pull the most concrete noun + verb from the window.

### 3.5 Output

List of `{timestamp_display, title}` pairs ordered by time.

## Step 4: Generate 3 Zaal-Voice Paragraphs

Input: parsed frontmatter + transcript body.
Output: 3 paragraphs, total 800-1100 chars, first-person.

### Paragraph 1 - Set the scene

Start with exactly:
`I sat down with <guest> (<role_at_org>) to talk <core_topic>.`

- `<role_at_org>` inferred from `guest_org` + summary context (e.g. "builder at
  Clanker", "organizer at Hubs Network"). Under 40 chars.
- `<core_topic>` = 3-7 word phrase from `summary`.
- Follow with 1-2 sentences of context on who the guest is + why this convo.
  Pull from `summary` + transcript opening.

### Paragraph 2 - What we actually covered

3-5 concrete beats from the episode. Rules:
- Name specific projects/people/orgs from `entities`.
- No hype words: skip "amazing", "incredible", "game-changing",
  "revolutionary". Use plain verbs: "walks through", "breaks down",
  "shares how", "explains".
- Grounded only - if it wasn't in the transcript, don't write it.
- Conversation-style verbs: "we talk about", "<guest> explains",
  "<guest> shares", "he/she walks through".

### Paragraph 3 - Why it matters

One or two sentences tying the episode to The ZAO / builders / musicians /
web3 coordination.
- Connect to `topics` and `action_items` when possible.
- If guest has a near-term CTA from `action_items[0]`, include it here.

### Voice constraints

- First-person singular: "I sat down", "we talked", "I asked". NEVER "we sat
  down" or "BCZ sat down".
- No emojis. No em dashes. Use hyphens.
- Say "Farcaster" not "Warpcast".
- No hashtags. No exclamation points.
- Contractions OK (I'd, we're, it's).
- Total 800-1100 chars. If over 1150, trim P2. If under 700, expand P2 with
  another concrete beat.

Output: `{p1, p2, p3}` as 3 plain strings. No leading/trailing whitespace.
No markdown.

## Step 5: Render Template + Validate

### 5.1 Render description body

1. Read `content/templates/youtube-description.md`.
2. Extract the section between `--- START BODY ---` and `--- END BODY ---`.
   Discard the comment header + markers.
3. Substitute placeholders:
   - `{{episode}}` -> `frontmatter.episode` (integer)
   - `{{guest}}` -> `frontmatter.guest`
   - `{{guest_alias}}` -> resolved `guest_alias`
   - `{{guest_role_at_org}}` -> inferred role string (e.g. "founder of POIDH",
     "builder at Clanker"). Used in P1 sentence only.
   - `{{guest_org}}` -> `frontmatter.guest_org`. Preserve casing from
     frontmatter (POIDH stays POIDH; Hangry Animals stays Hangry Animals).
   - `{{core_topic}}` -> 3-7 word topic from summary
   - `{{one_line_context}}` -> 1 sentence about guest + why
   - `{{paragraph_2}}` -> P2 string
   - `{{paragraph_3}}` -> P3 string
   - Chapter placeholders -> substitute chapters from Step 3. CHAPTERS block
     is at the BOTTOM of the description, after THE ZAO. If fewer than 10:
     pad by repeating template lines 2 through N-1. If more than 11: extend
     the CHAPTERS block with additional `{{mm:ss}} - {{title}}` lines in
     order before the Outro line.
   - `{{entities.people}}` -> comma-separated `{Name} (@handle)` (or `{Name}`
     if no handle). If empty, omit the `People:` line.
   - `{{entities.projects}}` -> comma-separated `{Project} - {url}` (or
     `{Project}` if url null). If empty, omit line.
   - `{{entities.orgs}}` -> same pattern. If empty, omit line.
   - If all three entity lines empty, omit the entire
     `MENTIONED IN THIS EPISODE` block header + body.
   - `{{guest_links}}` -> one line per link: `- {platform}: {value}`. If
     empty, omit the entire `FOLLOW {{guest}}` block.
   - `{{playlist_url}}` -> `https://youtube.com/@bettercallzaal` (channel
     fallback until a pinned playlist URL exists).

### 5.2 Render tags

1. Read `content/templates/youtube-tags.txt`.
2. Take the single non-comment, non-blank line.
3. Substitute:
   - `{{guest}}`, `{{guest_alias}}`, `{{guest_org}}` from frontmatter.
   - `{{topics}}` -> `frontmatter.topics` joined by `, `, hyphens -> spaces.
   - `{{keywords}}` -> first 5 of `frontmatter.keywords`, hyphens -> spaces,
     joined by `, `.
4. Deduplicate tags (case-insensitive). Strip trailing comma.

### 5.3 Validators

All 12 must pass. If any fails, fix the rendered output and re-check.

| # | Check | Fix |
|---|-------|-----|
| 1 | Body length 2,000 <= chars <= 4,800 | <2,000: expand P2. >4,800: trim P2, then chapter titles. |
| 2 | Chapter count >= 10 and <= 15 | <10: revisit Step 3.3 reduction. >15: drop weakest transition-phrase candidates. |
| 2a | First line is exactly `BCZ YapZ Episode {{episode}} w/ {{guest}} from {{guest_org}}` | Use as YouTube video title too. |
| 2b | CHAPTERS block is at the BOTTOM of the body (after THE ZAO block) | Re-order if rendered earlier. |
| 3 | First chapter line starts with `0:00 - ` | Replace first chapter with `0:00 - Welcome + who is <guest_alias>`. |
| 4 | Every chapter title <= 50 chars | Truncate at last space before char 50. |
| 5 | No blank lines between chapter lines | Strip blank lines in CHAPTERS block. |
| 6 | Tags line <= 480 chars | Drop trailing `{{keywords}}` entries until under 480. |
| 7 | `@zaal` appears in "BCZ YAPZ" Farcaster line (NOT `@bettercallzaal`) | Replace. |
| 8 | `/zao` appears in "THE ZAO" Farcaster-channel line (NOT `/thezao` or `/the-zao`) | Replace. |
| 9 | Contains `Farcaster`, does NOT contain `Warpcast` | Replace `Warpcast` with `Farcaster`. |
| 10 | Contains no emoji chars (U+1F000-U+1FFFF range) | Strip. |
| 11 | Contains no em dash (U+2014) | Replace with hyphen or reword. |
| 12 | No `#` hashtag tokens in body | Strip hashtags. |

## Step 6: Write Output + Copy to Clipboard

### 6.1 Write output file

Path: `/Users/zaalpanthaki/Documents/bcz-yapz/content/youtube-descriptions/<slug>.md`

`<slug>` = input slug (preserves `undated-` prefix for undated transcripts).

**Before writing:** re-count the final rendered body length and chapter count
AFTER all validators have run and fixes applied. The frontmatter values below
reflect the final state, not pre-validation estimates.

`gaps_flagged` = count of UNIQUE `(entity_name, category)` pairs actually
appended to `link-map.gaps.md` during this run (after dedupe against existing
lines). NOT total unresolved count - a re-run of the same transcript would
show `gaps_flagged: 0` since all pairs are already in the file.

File format:

```
---
source_transcript: content/transcripts/<slug>.md
generated_by: /bcz-yapz-description
generated_at: <ISO 8601 timestamp>
date_iso: <date_iso or null>
date_display: <date_display>
char_count_body: <int>
chapter_count: <int>
tag_char_count: <int>
gaps_flagged: <int>
---

## YouTube Description Body

<rendered body>

## YouTube Tags

<rendered tags line>

## Skill Run Notes

- Chapters extracted: <count>
- Entities resolved: <resolved> / <total>
- Gaps appended: <count>  (see content/templates/link-map.gaps.md)
```

### 6.2 Copy body to clipboard

Write ONLY the rendered body (no YAML, no tags, no skill metadata) to a temp
file, then:

```bash
pbcopy < /tmp/bcz-yapz-body.txt
rm /tmp/bcz-yapz-body.txt
```

### 6.3 Final response

Respond with under 10 lines, no emojis:

```
Generated: content/youtube-descriptions/<slug>.md
Body: <char_count> chars, <chapter_count> chapters
Tags: <tag_char_count> chars
Gaps: <n> (appended to link-map.gaps.md) / none
Body copied to clipboard. Paste into YouTube description.
Tags: <rendered tags line>
```
