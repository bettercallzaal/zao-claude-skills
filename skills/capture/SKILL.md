---
name: capture
description: Capture content-as-source (screen-recorded Reels, YouTube videos, podcasts, articles, paste-in transcripts) and file it as a research/captures/NNN-* note - distinct from /meeting which handles human-to-human calls. Use when Zaal types `/capture <path-or-url>`, when Zaal shares a Reel/TikTok/YouTube/podcast link he wants extracted as a source, or when content lacks attendees/decisions/actions (monologue creators, productivity gurus, talks, demos). Routes to research/captures/, skips Bonfire+Airtable+tracker by default, focuses on extracting the FRAMEWORK or CLAIM and mapping it to existing Zaal/ZAO patterns.
---

# /capture - ZAO Content-Source Capture

Sibling to `/meeting`. Same transcription stack, different routing.

**The rule:** if the input has attendees + decisions + actions, it is a meeting -> `/meeting`. If the input is content (one creator talking, an article, a podcast, a Reel) being captured AS A SOURCE for Zaal's planning / research / inspiration, it is a capture -> this skill.

Spawned from doc 753 (pjdlifts Reel mis-routed through /meeting on 2026-05-25). The /meeting skill explicitly bans inventing attendees/decisions; this skill is what those cases route to.

## When to fire

- Zaal types `/capture <path-or-url>` explicitly.
- Zaal shares a Reel / TikTok / YouTube / podcast link with intent to extract it ("save this", "useful frameworks here", "I want to remember this").
- Zaal shares a screen-recording or audio file that is clearly monologue / one-creator content.
- A `/meeting` run detects single-speaker content with no Q&A markers (Phase 1.5 in /meeting - suggest re-route to here).

## When NOT to fire

- Human-to-human conversation - use `/meeting`.
- Article research with intent to write back to it / engage with sources - use `/zao-research`.
- Quick note-to-self - just type the note; capturing should produce a structured framework extraction, not a brain dump.
- Live audio capture - that is ZAO Craig (doc 670), not this skill.

## Input detection

- **local_media** - path ending `.m4a` / `.mp3` / `.wav` / `.mp4` / `.mov` / `.opus` that exists on disk.
- **paste** - 200+ char block of text in chat or as the argument (transcript, article body, transcript dump).
- **video_url** - YouTube / TikTok / Vimeo / direct video URL -> yt-dlp pulls video + auto-captions.
- **page_url** - Instagram / X / podcast page / blog / Substack URL -> WebFetch (or ladder per `.claude/rules` fetch order) for the page; if the page is the source itself (article / blog), no transcription needed.
- **instagram_reel** - special case: Instagram is login-walled, WebFetch returns no content. Tell the user: "I can't fetch Instagram Reels directly. Screen-record it on your phone or mac, then `/capture <path-to-recording>`. The recording captures audio + your browser/app context, which is more useful than the raw Reel anyway."
- **unclear** - one clarifier: path, paste, or URL?

## Phase 0 - Acquire transcript / content

### Mode: paste
Skip Phase 0.

### Mode: local_media
Reuse `/meeting` scripts (do NOT duplicate - they live at `~/.claude/skills/meeting/scripts/`):

```bash
bash ~/.claude/skills/meeting/scripts/extract-frames.sh "$MEDIA_PATH"   # video only
bash ~/.claude/skills/meeting/scripts/transcribe.sh "$MEDIA_PATH"        # mlx-whisper local
```

Skip `diarize.sh` for captures. Captures are typically single-speaker; diarization adds latency without value. If the heuristic-check below flags multi-speaker, re-route to `/meeting`.

### Mode: video_url

```bash
yt-dlp --write-auto-sub --sub-lang en --skip-download -o "/tmp/capture-%(id)s.%(ext)s" "$URL"
# pulls .en.vtt of auto-captions; no video download for transcript-only path

# If auto-captions absent, fall back: download audio + transcribe
yt-dlp -x --audio-format mp3 -o "/tmp/capture-%(id)s.%(ext)s" "$URL"
bash ~/.claude/skills/meeting/scripts/transcribe.sh "/tmp/capture-<id>.mp3"
```

For framework-style content (the high-value case), auto-captions are usually enough. Transcribe only when captions fail.

### Mode: page_url

For pages, climb the same fetch ladder /meeting uses for non-local content:

1. WebFetch first.
2. If empty / login-walled -> exa `web_fetch`.
3. Notion / JS-heavy -> Playwright / `/browse`.
4. Dead -> Wayback Machine.

For Instagram Reels specifically, do NOT try - just tell the user to screen-record (see input detection above).

### Mode: instagram_reel
Bounce back to the user with the screen-record instruction. Do not invent content from the URL fragment alone.

## Phase 0.5 - Heuristic: am I actually a meeting?

Before extraction, check if this is actually a meeting that should have gone to `/meeting`:

- Count distinct "speaker turn" markers in the raw transcript (`[Speaker N]`, "Person A:", interruptions, Q&A markers like "what do you think?", "yeah totally").
- If 2+ distinct speakers with back-and-forth dialogue: tell the user "this looks like a meeting, not a capture. Re-route to `/meeting <path>`?" and exit.
- If single speaker monologue OR article body: continue as a capture.

This is the inverse of /meeting Phase 1.5 (which sends single-speaker content here). Both skills should agree.

## Phase 1 - Extract framework + claims

Single pass, NOT multi-pass (captures are usually short + monologue, not the multi-perspective extraction /meeting needs).

Extract one JSON object:

```json
{
  "capture": {
    "date_captured": "YYYY-MM-DD",
    "date_published": "YYYY-MM-DD or empty",
    "title": "...",
    "creator": "@handle or 'Unknown'",
    "creator_platform": "Instagram | YouTube | TikTok | Substack | Podcast | Article | Other",
    "source_url": "... or local file path",
    "duration_min": 0,
    "topic_folder": "events | community | dev-workflows | business | etc"
  },
  "framework_or_claim": {
    "name": "ADVANCED acronym | The 4-hour Rule | <whatever>",
    "kind": "acronym | rule | model | tactic-list | case-study | argument | other",
    "components": [
      {"label": "A", "name": "Anchor hours", "verbatim_quote": "..."}
    ]
  },
  "key_quotes": [
    {"text": "...", "context": "where in the source"}
  ],
  "maps_to_zaal_stack": [
    {"capture_component": "Anchor hours", "zaal_already_does": "YES | NO | PARTIAL", "memory_or_doc_reference": "user_zaal_schedule.md", "gap": "what is missing or what to refine"}
  ],
  "memory_candidates": [
    {"slug": "project_xyz", "what": "what new memory might be worth, if any"}
  ]
}
```

Rules:
- `framework_or_claim` is the load-bearing field. If you can't name a framework / claim / argument, the content probably isn't worth capturing - tell Zaal "no clear framework extracted, skip?" before writing.
- `verbatim_quote` per component is required. Captures live or die on accurate verbatims; paraphrase = noise.
- `maps_to_zaal_stack` is the value-add over a raw transcript dump. Cross-check every component against `~/.claude/projects/-Users-zaalpanthaki-Documents-ZAO-OS-V1/memory/` and ZAO research docs (grep for `user_zaal_*`, `project_*`, key entities).
- `memory_candidates` is opt-in via Phase 2; usually empty.

## Phase 2 - Present + confirm

Show extracted JSON inline as markdown tables (framework components, key quotes, mapping). Then ask:

> "Extracted <framework name> with <N> components, <M> quotes.
> Topic folder: <inferred> - correct? (events / community / dev-workflows / business / other)
> Edits? If clean, which targets fire?"
>
> Targets:
> - [x] research/captures/NNN-<slug>/README.md (default ON, always written; ALWAYS in ZAOOS)
> - [x] _captures-index.md row (default ON)
> - [ ] Bonfire knowledge-graph episode (opt-in via --bonfire, default OFF; flip ON if content names real people / projects worth graph-querying)
> - [ ] Tracker action(s) (opt-in via --tracker, default OFF; for self-imposed todos worth surfacing on the Kanban)
> - [ ] Memory writes (per-candidate confirm; usually empty)
> - [ ] Clipboard next-actions page (opt-in via --clipboard, default OFF)

Wait for Zaal's reply before any destructive write.

## Phase 3 - Distribute

### research/captures/NNN-<slug>/README.md (always)

Find next doc number across `research/` (collision-safe per doc 663):

```bash
find /Users/zaalpanthaki/Documents/ZAO\ OS\ V1/research -maxdepth 3 -type d -name '[0-9]*' | grep -oE '/[0-9]+' | tr -d '/' | sort -n | tail -1
```

Slug = `<creator-handle-without-@>-<2-3-topic-keywords>-<source-type>`. Doc 753 example: `pjdlifts-advanced-acronym-reel-capture`.

Use the template at `references/capture-template.md` (mirrors doc 753 shape). Required sections:

- Frontmatter (per /zao-research v2 standard, plus `captured-from`, `creator`, `source-url`)
- "The framework" - table of components with verbatim quotes
- "Why captured" / context section
- "How it maps to Zaal's stack" - mapping table from extraction
- Source - FULL / PARTIAL / FAILED classification per /zao-research Hard Req #11
- Next Actions - personal todos

Write to `research/captures/NNN-<slug>/README.md`. Leave on `ws/` branch, do NOT commit - Zaal commits or asks for edits.

### _captures-index.md (always)

`research/captures/_captures-index.md` - mirror of `_meetings-index.md` pattern. One canonical list of every capture ever processed.

If the file does not exist, create it:

```markdown
# Captures Index

Every content-source captured via /capture, newest first. Maintained automatically by the skill.

| Date | Creator | Platform | Title | Framework | Doc |
|------|---------|----------|-------|-----------|-----|
```

Prepend the new capture as the first data row.

### Bonfire episode (opt-in via --bonfire)

If `--bonfire` flag passed and `$BONFIRE_API_KEY` present, post ONE episode per capture (not per framework component - too noisy):

```json
{
  "episodes": [
    {
      "name": "capture:<date>:<framework-name>",
      "body": "Captured a <kind> from <creator> on <platform> on <date>: <framework name>. <one-sentence summary>. Key components: <component list>. Source: <url>.",
      "source_tag": "capture:<slug>"
    }
  ]
}
```

Use the existing `~/.claude/skills/meeting/scripts/bonfire-episode.sh` script - the JSON shape is compatible. Best-effort, never aborts the run.

### Tracker action(s) (opt-in via --tracker)

If `--tracker` flag passed, take any "Next Actions" rows where `Owner = @Zaal` AND mark them as `kind:research` tracker tasks:

```bash
for action in self_imposed_actions:
  ~/bin/zao-tracker research "<capture-doc-num>" "capture follow-up: <action title>"
```

Default OFF because most captures generate personal-planning todos that don't belong on the team Kanban.

### Memory writes (per-item confirm)

Same flow as /meeting: show proposed memory file, get Zaal's OK, write under `~/.claude/projects/-Users-zaalpanthaki-Documents-ZAO-OS-V1/memory/`, append index line to `MEMORY.md`.

### Clipboard (opt-in via --clipboard)

If `--clipboard` flag passed: build a clean "next actions from this capture" block and pass to `/clipboard` skill. Most captures don't need this (the recap doc itself is the artifact).

### Skipped surfaces (NOT routed by default)

- Telegram block - captures aren't shared, they're personal. Use `/socials` if you want to post about a capture.
- Airtable CRM - no real attendees, no contact rows.
- Calendar event update - not applicable.
- Meetings index - captures get their own index, not the meetings one.

## Hard guardrails

- **Never write a capture as a meeting in research/events/.** That's exactly the bug that spawned this skill (doc 753 had to be filed under events/ because captures/ didn't exist yet).
- **Never invent quotes, claims, or framework components not in the source.** If the source is hard to fetch (Instagram, paywall), bounce back to the user for a screen-recording.
- **Never auto-write memory entries** - per-item Zaal confirm.
- **Bonfire / tracker / clipboard are opt-in flags** - default behavior is local-only filesystem writes.
- **No emojis. No em dashes.** Per global Zaal feedback.

## Anti-patterns

- Do NOT use the /meeting flow with one fake attendee just to force-route. That's the bug.
- Do NOT collapse `framework_or_claim` into a paraphrase. Verbatim quotes are the whole point.
- Do NOT skip the `maps_to_zaal_stack` cross-check. A capture without "how does this connect to what I already do" is just a transcript dump - low value.
- Do NOT post to Bonfire by default. Captures of "anonymous productivity gurus" pollute the graph; only flip --bonfire on for content that names real people or named systems.

## CLI flags summary

```
/capture <path-or-url>            # default: local-only, no Bonfire/tracker/clipboard
/capture <path-or-url> --bonfire  # also post to Bonfire KG
/capture <path-or-url> --tracker  # also create kind:research tracker rows for self-imposed actions
/capture <path-or-url> --clipboard # also drop next-actions to /clipboard skill
```

## Doc numbering (collision-safe)

Same rules as /meeting + /zao-research. `git fetch origin`, scan `research/` for max, increment defensively if folder already exists.

## References

- `references/capture-template.md` - the doc shape (modeled on doc 753)
- `~/.claude/skills/meeting/scripts/` - reused transcription + frame extraction
- Doc 753 (`research/events/753-pjdlifts-advanced-acronym-reel-capture/`) - the case that spawned this skill; will be moved to `research/captures/` if/when batch-rehome is run, or stay in events/ as historical artifact
- Doc 670 (`research/events/670-...`) - meeting recap gold standard, NOT to be confused with capture shape
- `/meeting` SKILL.md - sibling skill, shares scripts, opposite content type

## Scripts (this skill)

For v1, this skill REUSES /meeting's scripts. No new scripts in `~/.claude/skills/capture/scripts/` unless a capture-specific need emerges (likely candidate: `fetch-creator-page.sh` for cleaner Reel / Substack landing-page metadata fetch).

## Evals

(deferred to v2 - add `evals/` with fixture transcripts once the skill has been used on 5+ real captures and the doc shape stabilizes)

## Engineering basis

Same as /meeting: doc 676 (skill-engineering best practices) + doc 673 (meeting capture design doc). This skill is the missing branch of doc 673's project-routing decision tree: "what if the input has no project because it has no attendees?"
