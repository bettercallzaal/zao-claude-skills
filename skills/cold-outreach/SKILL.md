---
name: cold-outreach
description: ZAO agentic cold-outreach kit. Research one target (LinkedIn URL / email / Twitter handle), draft a personalized 50-100 word DM in Zaal's voice per the angle you pick (Fractal / Music / ZABAL Games / Festivals / umbrella), surface for human approval before send, then log the touch to Airtable CRM AGENTIC. Use when asked to "draft a cold DM", "reach out to X", "write a LinkedIn message to Y", or to run the workflow on a target person.
---

# ZAO Cold Outreach Kit

> The doc-743 workflow turned into a runnable agent skill. Any ZAO team member (Zaal, Iman, ThyRev, Samantha, Tyler) loads this in their Claude Code session and runs single-target outreach end-to-end: research -> draft -> human-approves -> manual send -> CRM logs the touch. No fully-autonomous sending. Each draft gets human eyes before it leaves your account.

**Lives at:** `~/.claude/skills/cold-outreach/SKILL.md` (global, all team members)
**Source of truth doc:** ZAOOS `research/business/743-agentic-cold-outreach-workflow/README.md`
**Companion scripts:** `scripts/zao-crm-sync/cold-outreach-draft.py` (research + draft) + `cold-outreach-write.py` (Airtable activity row write, ship next session) + `cold-outreach-reply-classify.py` (5-class triage, ship next session)

---

## When to fire this skill

- User says "draft a cold DM to [name / LinkedIn URL]"
- User says "reach out to [person / list] about [angle]"
- User shares a LinkedIn URL + asks for outreach
- User pastes contact details + wants a personalized message
- User runs `/cold-outreach <linkedin-url>` (if/when wired as slash command)

## Inputs the skill needs

Either:
- A LinkedIn URL (highest signal, agent will scrape public profile if accessible)
- A name + company combo (agent looks up via Apollo / Hunter if configured)
- A direct paste of name + role + company + 1-2 context lines from user

Plus optional:
- Angle hint (Fractal / Music / ZABAL Games / Festivals / umbrella) - if user doesn't pick, agent infers from target's industry / keywords
- Channel hint (LinkedIn DM / Cold email / X DM / Farcaster DM)
- Personalization level (2-3 templated default, 4 Tier-1 hand-crafted)

## The workflow (per single target)

### Step 1 - Research the target (3-5 min cap)

Pull what you can in 3-5 min - don't go over without explicit Tier-1 flag.

Signal sources, ranked by reply-rate correlation (per doc 743 research):

| Signal | Lift | How to fetch |
|--------|------|--------------|
| Funding announcement / job change in last 30 days | 4-5x baseline | Apollo intent triggers, Crunchbase, LinkedIn activity scan |
| Product launch mentioning ZAO-relevant category | 3x | Company blog RSS, GitHub releases, ProductHunt |
| Recent public post on relevant topic | 2-3x | LinkedIn activity API, X recent posts via zao-fetch-x.sh |
| Mutual connection to ZAO community | 2x | LinkedIn mutual graph, ZAO Farcaster follower set, Bonfire query |
| Speaking / podcast appearance | 1.5x | LinkedIn activity, Podcast Index search |
| Generic profile (no recent activity) | 1.0x baseline | Skip unless Tier-1 |

If after 3-5 min you have ZERO signal:
- Mark target `low-confidence` in the draft
- Suggest user defer (no signal = predicted reply rate <2%)
- Move to next target

### Step 2 - Score + pick angle

Use the doc 743 scoring rubric (also encoded in doc 742):

```
score = 0
+ funding_announcement_last_30_days * 25
+ job_change_to_CEO_CRO_last_30_days * 20
+ product_launch_mentioning_zao_category * 15
+ has_active_twitter * 5
+ has_active_linkedin_posts_last_30d * 5
+ industry_fit_with_zao_angle * 10
+ mutual_connection_to_ZAO_community * 8
- existing_in_DoNotContact_table * 1000
- last_touched_within_90_days * 100
```

Then pick the angle (Fractal / Music / ZABAL Games / Festivals / umbrella). Use the doc 742 assignment logic:

| Industry / role | Angle |
|-----------------|-------|
| Music / performing arts / creator | **B - WaveWarZ + ZAO Music** |
| Events / festival / venue | **D - ZAO Festivals / ZAOstock** |
| Crypto / blockchain / web3 / DAO | **C - ZABAL Games (builder bootcamp)** |
| Investors / VCs / governance / partners | **A - ZAO Fractal (governance experiment)** |
| Creator-economy-adjacent | **B** (music is the closest) |
| Default | **C** (broadest tech-founder audience) |

### Step 3 - Draft the message

Constraints (NON-NEGOTIABLE, lifted from `bot/src/zoe/brand.md` + doc 743):

**Voice:**
- No em dashes (use hyphens)
- No emojis
- No marketing words: leveraging / streamline / synergize / cutting-edge / unlock / paradigm / game-changer / unprecedented / transformative
- Spartan + active voice
- Lead with the outcome, not the process
- Short paragraphs (max 2 sentences), blank line between

**Banned phrases (ALL of these scream AI and tank reply rate per WriteHuman 80K-sample study):**
- "I hope this finds you well"
- "I came across your profile"
- "I'd love to connect / explore synergies / hop on a quick call"
- "Trust this email finds you well"
- "I noticed you work in the X space"
- Generic "saw your post" without quoting it
- "ensuring / highlights / supports / reflects" (hedging verbs)
- "rather than" (AI loves this construction)
- "It's worth noting / generally speaking / in many cases" (AI hedging preambles)
- Tidy tricolons ("fast, reliable, affordable" - AI defaults to 3 items)

**Structure** (proven 18-42% reply rate per ReactIn + SRG + Aurium 2026):

```
Hi [First Name],

[1 specific observation about them - quote a phrase from their post, or name a specific signal: "saw you raised X" / "watched your talk at Y" / "noticed [Company] just shipped [Z]"]

[1 connection to ZAO that matches this signal - the angle-specific hook, e.g. for governance fit: "We've been running fractal governance every Monday for 100+ weeks. Soul-bound Respect tokens, no plutocracy."]

[1 binary question OR soft ask - NOT a calendar link]

[Sign-off: name + The ZAO + thezao.com]
```

**Length: 50-120 words max.** Mobile-first. Hook lands in first 30 chars (LinkedIn truncates).

**One ask, not three.** Per ReactIn rule #3.

**Angle hooks (mix-and-match per target):**

A. **Fractal (governance):** "We've been running fractal governance every Monday for 100+ weeks. Soul-bound Respect tokens, no plutocracy, on-chain on Base." Hook: "If governance design is in your wheelhouse, would value 15 min on what we learned that didn't work." Or: "Curious what governance experiments you've watched closely."

B. **WaveWarZ + ZAO Music:** "We run 11 live music battles a week on X Spaces with on-chain credentials on Base. Real artists, smart-contract-tracked outcomes." Hook: "If creator-economy primitives are on your radar, worth a chat?" Or: "We're seeing patterns in artist behavior worth comparing notes on."

C. **ZABAL Games (builder bootcamp):** "Running a June-through-August builder bootcamp called ZABAL Games for Farcaster-native vibe-coders. 8 mentors, real prizes, working code at the end." Hook: "Open to engineers in your orbit who'd want to ship something with a small focused community." Or: "If you have devs who want a real challenge, send them."

D. **ZAO Festivals / ZAOstock:** "We're anchoring 2026 around an in-person October festival in Ellsworth Maine with three pop-ups building to it. Real artists, real venue, decentralized funding mechanic." Hook: "If event partnerships or festival sponsorships are something you're paying attention to, would value 15 min."

Umbrella: "We're a decentralized impact network. The ZAO ships music, governance, and on-chain credentials as one stack. If any of that lines up with what you're paying attention to, just reply with which one and I'll send the deeper read."

### Step 4 - SURFACE FOR APPROVAL (NEVER auto-send)

Output the drafted message in the chat for user (Zaal or team member) to review.

Format:

```
=== DRAFT FOR APPROVAL ===
Target: [Name], [Title] at [Company]
Signal used: [the specific signal you anchored on]
Angle: [A/B/C/D/umbrella]
Channel: [LinkedIn DM / Cold email / X DM / Farcaster DM]
Personalization level: [2-3 templated / 4 Tier-1]
Reply-rate expectation: [9-12% per Warmysender Level 3 / 11.7% Level 4]

----- MESSAGE -----
[the drafted message]
-------------------

To send:
1. Open [target's LinkedIn URL]
2. Click Message (or Connect if not yet connected)
3. Paste this message
4. Send

After send, reply "sent" in chat and I will log the activity row to Airtable.
```

**Wait for explicit human approval.** Do NOT call the Airtable write tool before user says "sent" or "approve + send".

### Step 5 - LOG to Airtable (after user confirms sent)

When user replies "sent" or "approved + sent" or similar:

1. Call `scripts/zao-crm-sync/cold-outreach-write.py --target <name> --channel <channel> --angle <angle> --message-summary "<1-line summary>"` (ships next session - until then surface what would be written for user to confirm)

2. The script writes ONE activity row to Airtable AGENTIC base:
   - type: `linkedin-dm-sent` / `email-sent` / `x-dm-sent` / `farcaster-dm-sent`
   - date: now
   - contacts: link to the contact (resolve by name + company)
   - direction: outbound
   - source: `cold-outreach-skill`
   - raw_source: optional - link to where the message was crafted (this conversation if no other anchor)
   - zao_relevance: per angle
   - summary: the message synthesis (NOT the full body - that lives in the user's LinkedIn DM history)
   - bonfire_episode_id: optional

3. If target doesn't yet exist in `contacts`, create a minimum row:
   - name + role + org + zao_connection: per angle assignment
   - met_via: `cold-outreach-skill 2026-MM-DD`
   - first_contact_date: today
   - last_touch_date: today

### Step 6 - Reply triage (when a reply lands)

When user pastes a reply they received OR the daily Gmail/LinkedIn sweep surfaces one:

Classify into one of 5 buckets per the doc 743 taxonomy:

| Class | What | Auto vs Human | SLA |
|-------|------|---------------|-----|
| **Positive** | Interested, asks question, signals meeting intent | Draft response for Zaal approval (70% auto) | 2 hrs |
| **Neutral** | Non-committal, soft engagement | Human nurture only (0% auto) | 24 hrs |
| **Objection** | Pushback with reason (timing/budget/fit) | Classify objection_type + route playbook (30% auto) | 4 hrs |
| **Unsubscribe** | Explicit opt-out | Immediate suppression sync (100% auto) | 1 hr |
| **Out-of-office** | Auto-reply | Defer + retry after return date (100% auto) | 7 days |

For Positive replies, draft a follow-up response (still per voice rules + ban list) + surface for approval. NEVER auto-send a response without human approval.

For Unsubscribe: log to Airtable contacts with `consent_for_graph = false` + add `do_not_contact_reason = "Unsubscribe"` field. Future runs of this skill SKIP this contact entirely.

For OOO: log + schedule retry after return date.

## Multi-touch sequencing

Per doc 743: 3-touch maximum for cold outreach (warmth-building goal, not pipeline-velocity).

| Touch | Day | Channel | Purpose |
|-------|-----|---------|---------|
| 1 | Day 0 | Primary (LinkedIn or X DM, channel-fit to target) | Hook + angle + soft ask |
| 2 | Day 3 | Different channel (email if touch 1 was LinkedIn) | Value-add, NOT "just bumping this" |
| 3 | Day 8 | Final | "Breakup": one final value-add + permission to close |

**STOP at 3 touches.** Do not auto-fire touch 4. Per ZAO research: 5+ touches trips spam complaints + tanks brand trust.

Wait for reply between touches. If reply lands, pause all future touches in the sequence.

## Channel selection per target

| Target signal | Pick channel for touch 1 |
|---------------|---------------------------|
| Active X account (has Twitter URL + recent posts) | X DM after 3-5 day public warmup (like/reply on their posts first) |
| Active LinkedIn (has post in last 30 days) | LinkedIn DM (connection request + note if not connected) |
| Web3-native with Farcaster handle | Farcaster DM (open-to-all, lowest friction) |
| Traditional B2B / music-industry / no X presence | Email (only if email is available - need Hunter enrichment first) |
| Has nothing public + only LinkedIn URL | LinkedIn DM as default |

## Compliance + safety

- **LinkedIn:** Manual native only. NO bots. Cap 15-30 connection requests/day. Never exceed +30% week-over-week volume increase. Avoid Heyreach / Expandi / Dripify (account ban risk 2026).
- **Cold email:** Send from `outreach.thezao.com` subdomain (NOT info@). Requires 2-4 week warmup before first send. SPF + DKIM + DMARC mandatory. Include unsubscribe footer + CAN-SPAM postal address. From 2026-08-02: EU AI Act Article 50 requires "drafted with AI assistance" disclosure footer if EU recipient.
- **X DM:** 10-20/day max. After warmup (engage on prospect's posts publicly for 3-5 days first).
- **Farcaster:** No published limit. Manual via Farcaster app. 5-10/day.

## What this skill does NOT do

- **Does NOT auto-send.** Every draft requires human approval before going out.
- **Does NOT mass-blast.** One target at a time, agent helps draft, human ships.
- **Does NOT bypass voice rules.** If a draft slips an em dash or a banned phrase, the agent should self-correct in the draft step. If the user catches one in approval, fix and re-surface.
- **Does NOT skip the CRM write.** After user confirms sent, the Airtable activity row MUST land.
- **Does NOT scrape LinkedIn at scale.** LinkedIn ToS + ban risk. Use Apollo / Hunter for enrichment; LinkedIn data only from human-eye scan of public profile.

## Team usage notes

- **Zaal:** primary user. Default voice = Zaal voice (per brand.md). Default signature: "Zaal Panthaki / The ZAO / thezao.com"
- **Iman:** can use for ZAO Devz outreach. Voice = Iman voice if running for his own DMs. Signature: "Iman Afrikah / The ZAO Devz"
- **ThyRev / Samantha / Tyler:** can use for their own slices. Each adapts the signature + voice constraint.

Override voice with `--voice <name>` flag if not Zaal. Skill defaults to Zaal voice.

## Source-of-truth references

- ZAOOS `research/business/743-agentic-cold-outreach-workflow/README.md` - the full workflow + research synthesis (7 parallel agents, 28 FULL sources)
- ZAOOS `research/business/742-zaal-panthaki-profile-dossier/` - Zaal voice + positioning context for personalization
- ZAOOS `research/business/737-airtable-agentic-crm-v3/` - Airtable CRM schema (write destination)
- ZAOOS `research/dev-workflows/739-claude-code-efficiency-native-mcps/` - native MCP connectors (Gmail send + GCal scheduling)
- ZAOOS `.claude/skills/zabal-games-context/SKILL.md` - distributable ZAO context (companion skill for ZABAL Games angle)
- ZAOOS `bot/src/zoe/brand.md` - voice rules
- ZAOOS `.claude/rules/pii-hygiene.md` - third-party data handling
- ZAOOS `~/.zao/private/` - off-repo dump location per PR #666

## Failure modes + recovery

| Symptom | Recovery |
|---------|---------|
| Draft contains em dash or banned phrase | Self-correct in the draft step. If slipped through, user catches it in approval - rewrite + re-surface |
| No signal found for target after 3-5 min research | Flag as `low-confidence`, suggest user defer or move to next target |
| Target already in `do_not_contact` (Airtable contacts table) | SKIP. Do not draft anything. Report to user. |
| Target was last touched <90 days ago | SKIP unless user overrides with explicit `--force` flag |
| LinkedIn rate limit / account flag | Pause LinkedIn sends for 48 hrs. Switch to alternative channel (X / FC / email) for the queue. |
| Cold email subdomain reputation damage | Stop all cold email sends. Investigate Postmaster Tools. Recovery may take 30-60 days. |
| Reply triage misclassifies (wrong bucket) | User overrides in Airtable. Log the override for future classifier feedback. |

## Update cadence

This skill is a working document. Edit `~/.claude/skills/cold-outreach/SKILL.md` directly as patterns evolve. Source-of-truth for any disputed claim: doc 743. Re-validate quarterly or when channel benchmarks shift significantly.
