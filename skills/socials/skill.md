---
name: socials
description: Generate platform-specific social posts for any ZAO content - newsletter distribution, event recaps, announcements, or anything worth sharing. Covers Farcaster/X (combined via Firefly), GCs, Telegram, Discord, LinkedIn, Facebook. Use when asked to "write socials", "social posts", "share this", "post about this", or after publishing a /newsletter post.
---

# Social Content Generator

Generate platform-specific posts for anything worth sharing - newsletter distribution, event recaps, milestones, announcements, or quick updates. Posts feel native, authentic, and aligned with BetterCallZaal's voice - grounded, rhythmic, and culturally aware.

## Two Modes

### Mode 1: Newsletter Distribution
- User provides a published Paragraph newsletter URL
- Posts reference and link to the newsletter
- Use when asked to "distribute the newsletter" or after /newsletter

### Mode 2: Standalone Posts (Default)
- User describes what they want to share (event recap, milestone, announcement, etc.)
- No newsletter URL needed
- Include a relevant link if one exists (website, GitHub, etc.)
- Use when asked to "write socials", "post about this", "share this"

If neither a URL nor content topic is clear from conversation context, ask: "What do you want to share?"

## Voice Rules

- Every post begins with **"ZM"** (ZAO Morning) - this is the daily greeting across the ZAO ecosystem
- No emojis
- No hashtags
- Lowercase casual when it fits - match the newsletter voice. "march ZOLs are in" not "March ZOLs Are In"
- Grounded, rhythmic, culturally aware
- Each platform should sound distinct - not duplicated
- **Lead with what was built and shipped.** Not hype, not vibes - concrete contributions. "built the team dashboard, pushed 4 teams to the website, processed the standup transcript" not "had an amazing kickoff meeting". Show the work, not the feeling about the work.
- Short content gets short socials. Don't pad a quick update into a long thread
- **NEVER reference work-day times.** Don't say "this morning", "today at 10am", "just got out of our standup". Use timeless language: "had our first standup" not "had our first standup this morning". Zaal has a day job - posts must not imply he's building during work hours.
- No em dashes. Hyphens only.
- **Contribution over celebration.** The audience should see what's being built, not how excited you are about building it. "shipped the /stock page with team rosters and partner cards" beats "so excited about the progress we're making". List the actual outputs.

## Platform Specs

Generate posts for ALL of these platforms in order:

### 1. Farcaster + X - Combined Post (via Firefly)
- **These are always the SAME post** - Zaal posts once via Firefly and it goes to both platforms
- Max 280 characters (X limit applies since it's cross-posted)
- Punchy, scroll-stopping rhythm
- Short sentences or fragments that make people pause or reflect
- Append link at the end if relevant
- If people are mentioned, tag them (X handles where known)
- Post to Farcaster /zao channel

### 2. X (Twitter) - Group Chat
- Conversational and insider tone - like texting the crew
- Assume readers already know ZAO, WaveWarZ, Songjam, and ongoing events
- Can be longer than main tweet - group chats aren't character-limited
- No link needed unless it fits naturally
- Reference inside jokes, shared context, recent events

### 3. Farcaster - /zao Group Chat
- Insider tone - like the X group chat but for the Farcaster crew
- Everyone here is deep in the ZAO ecosystem already
- Conversational, no explanation needed
- Can reference fractals, Songjam, WaveWarZ, ZOE without context
- Append newsletter link

<!-- NOTE: Farcaster Other Communities is paused for now but the channel list is preserved here for future use:
  ZAO ecosystem: /songjam, /music, /base, /nouns
  General: /build, /thecreators, /mindfulness, /philosophy, /farcaster, /founders
  When re-enabled: suggest 3-5 channels per post with custom 1-2 sentence posts native to each community's vibe -->

### 5. Telegram Group Chat
- Direct and friendly, like a note to the crew
- One or two sentences max
- Append newsletter link

### 6. Discord Group Chat
- Casual community tone
- Can reference events, collabs, shared energy, or ask a question
- Slightly longer than Telegram - Discord is for discussion
- Append newsletter link

### 7. LinkedIn
- Professional but still authentic - not corporate
- Start with "ZM" like every other platform
- Frame the day's content through a builder/founder/community lens
- LinkedIn audience doesn't know ZAO - give 1 line of context on first mention
- Longer than X, shorter than Farcaster /zao - aim for 3-5 sentences
- End with the newsletter link on its own line
- No "I'm humbled" or "thrilled to share" - just say what happened

### 8. Facebook
- Start with "ZM"
- Warm, personal, community tone - Facebook is where family and IRL friends see this
- Less crypto/Web3 jargon than other platforms - translate for normies
- Can be slightly longer and more conversational
- Append newsletter link
- Good place to reference IRL events (ZAO Stock, Bar Harbor meetups, Red Sox)

### 9. Video Platforms (Only if newsletter has a video element)

Skip this section entirely if no video is involved.

**TikTok:**
- Caption starts with "ZM"
- Title: Catchy, emotionally clear
- Tags: 5-10 comma-separated keywords (no #)

**YouTube:**
- Description starts with "ZM"
- Title: Descriptive and emotionally clear
- Tags: 5-10 comma-separated keywords (no #)

## Output Format

Use the `/clipboard` skill pattern: write an HTML page to `/tmp/clipboard.html` with all posts organized by platform, each with its own Copy button. Open in browser automatically.

The HTML should have:
- Each platform as a labeled section with clear visual separation
- Click-to-copy on each post block
- Character count shown for Farcaster/X combined post (280 char limit)
- Dark theme matching ZAO aesthetic (bg #0a1628, accent #f5a623)
- The link pre-filled in every post that needs it

**Do NOT output posts as plain text in the chat.** The whole point is the browser clipboard page. Just say "opened in browser" and let the user copy from there.

## Workflow

### Mode 1: Newsletter Distribution
1. Get the published newsletter URL from the user
2. Read/fetch the newsletter content if not already in conversation
3. Extract the emotional essence and key themes
4. Generate all platform posts
5. Write HTML to `/tmp/clipboard.html` and open in browser

### Mode 2: Standalone Posts
1. Use conversation context to understand what to share
2. Generate all platform posts
3. Write HTML to `/tmp/clipboard.html` and open in browser

### Platform posting order (Zaal's actual workflow):
1. **Firefly** - copy the Farcaster/X combined post, post once via Firefly (hits both)
2. **X GC** - copy, paste in X group chat
3. **Farcaster GC** - copy, paste in Farcaster /zao group chat
4. **Telegram** - copy, paste in TG group
5. **Discord** - copy, paste in Discord
6. **LinkedIn** - copy, paste on LinkedIn
7. **Facebook** - copy, paste on Facebook

The clipboard page sections should be in THIS order so Zaal can go top to bottom.

## Scaling Posts to Content Size

| Content Type | FC/X (Firefly) | X GC | FC GC | Telegram | Discord | LinkedIn | Facebook |
|-------------|----------------|------|-------|----------|---------|----------|----------|
| Quick update | 1-2 sent + link | 1-2 sent | 1-2 sent | 1 sent | 1-2 sent | 2-3 sent | 2-3 sent |
| Standard | 2 sent + link | 2-3 sent | 2-3 sent | 1-2 sent | 2-3 sent | 3-5 sent | 3-5 sent |
| Announcement | 2-3 sent + link | 3-5 sent | 3-5 sent | 2 sent | 3-5 sent | 4-6 sent | 4-6 sent |

Don't make a quick update sound like a major announcement across socials.

## Anti-patterns

- Don't hype. Lead with what was built, shipped, or decided - not how you feel about it.
- Don't summarize with emotion. List concrete outputs.
- Don't duplicate the same post across platforms. Each should feel native to that platform.
- Don't use em dashes. Hyphens only.
- Don't use emojis or hashtags.
- Don't add CTAs like "check it out" or "link in bio". Let the link sit naturally at the end.
- Don't over-explain. The audience on each platform has different context levels - write to that.
- Don't over-capitalize. Match the lowercase casual voice.
- Don't pad short days into long posts. Match the energy.
- Don't forget ZM. Every social post starts with it, even if the newsletter itself skipped it for an announcement opening.
- Don't say "excited", "thrilled", "amazing progress", "incredible". Just say what shipped.
