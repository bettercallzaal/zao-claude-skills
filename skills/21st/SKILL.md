---
name: 21st
description: Search, generate, and adapt UI components from 21st.dev's marketplace + Magic MCP for ZAO surfaces (ZAO OS, ZAO Stock, BCZ, FISHBOWLZ-replacement, ZOE chat). Use when adding/refreshing a UI surface and you want to start from a vetted pattern instead of from scratch. Auto-applies ZAO stack (Next 16, React 19, Tailwind v4) + brand tokens (#0a1628 navy, #f5a623 gold) + repo rules (mobile-first, "use client", Biome, no inline styles).
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, mcp__magic-mcp__21st_magic_component_inspiration, mcp__magic-mcp__21st_magic_component_builder, mcp__magic-mcp__21st_magic_component_refiner, mcp__magic-mcp__logo_search
argument-hint: "<natural-language description of the component or surface you want>"
---

# /21st - ZAO Component Search + Generate + Adapt

Wraps 21st.dev Magic MCP for ZAO repos. Cost-aware: free tools first, paid only on user confirmation.

## Prereq (one-shot per machine)

```bash
# Generate API key at https://21st.dev/magic/console
npx @21st-dev/cli@latest install claude --api-key <YOUR_KEY>
# Restart Claude Code; verify with: /mcp list   (should show magic-mcp)
```

API key handling: never paste in chat or commit. Installer writes it into Claude Code settings (local only).

## Decision Tree (run in order)

### Step 1 - Understand intent

Parse `$ARGUMENTS` into:
- **Surface** (which ZAO project / page): if not stated, ask. Default to repo invoked from.
- **Component type** (hero, CTA, pricing, chat, etc.): pick the closest 21st category.
- **Constraints**: default to ZAO defaults below.

### Step 2 - Always start with FREE Inspiration Search

Call `21st_magic_component_inspiration` with a query that includes:
- Component type
- "dark theme, navy + gold" (ZAO default)
- "mobile-first" (ZAO default)
- Surface context (e.g. "festival sponsor tier", "wallet-gated audio room")

Skim results. Surface top 3-5 to the user with one-line summaries.

### Step 3 - Brand SVG search if any logos referenced

If `$ARGUMENTS` mentions brand logos (Farcaster, Base, Spotify, etc.), call `logo_search` for each. Free.

### Step 4 - Decide path with the user

Present 3 options:

A. **Lift directly** (free, fastest): pick top Inspiration result; this skill adapts it.
B. **Refine an Inspiration result** (Pro $20/mo): one MCP call to `21st_magic_component_refiner` with ZAO context.
C. **Generate fresh variants** (Pro): call `21st_magic_component_builder` with brand tokens; user picks 1 of 5.

If no Pro key OR user prefers free, default to A. Never silently spend Pro credits.

### Step 5 - Adapt to ZAO stack (always run)

Whether lifted or generated, sweep code for:

| Sweep | Action |
|---|---|
| Tailwind v3 `@layer` syntax | Convert to v4 |
| Missing `"use client"` on hook-using component | Add at top |
| Inline styles | Convert to Tailwind classes |
| CSS modules | Convert to Tailwind classes |
| Hardcoded colors (any `#` color that isn't `#0a1628` or `#f5a623`) | Flag, replace with brand tokens or Tailwind dark palette |
| `clsx(...)` import | Replace with `cn` from `@/lib/utils` |
| Desktop-first responsive (`lg:` then narrower) | Restructure mobile-first (`sm:`, `md:`, `lg:` ascending) |
| Missing focus rings | Add `focus-visible:ring-2 focus-visible:ring-amber-400` |
| Image src external URL | Confirm with user; default to local `/public/images/...` |

Use `Edit` to apply sweeps; never `Write` over a freshly generated file before sweeping.

### Step 6 - Place file in right ZAO directory

| ZAO project | Default dir |
|---|---|
| ZAO OS V1 | `src/components/<feature>/` |
| ZAO Stock site (TBD repo) | `app/components/` |
| BCZ portfolio | `components/` |
| FISHBOWLZ-replacement / Juke embed | `src/components/audio/` |
| ZOE dashboard | `apps/zoe/components/` |

Always confirm path with user before writing.

### Step 7 - Tell the user

Output:
- File path written
- Source (Inspiration slug or generation prompt)
- Cost (free / Pro N credits)
- Sweep summary
- Next step suggestion

## ZAO Defaults (Always Pass to Magic MCP)

```
brand_tokens: { primary: "#f5a623", background: "#0a1628", text: "#e2e8f0" }
stack: "Next.js 16 App Router, React 19, Tailwind v4, TypeScript 6"
constraints: ["dark theme", "mobile-first", "no inline styles", "use cn from @/lib/utils", "use client where hooks/handlers"]
```

## Cost Awareness

| Tool | Cost | When |
|---|---|---|
| `21st_magic_component_inspiration` | Free | Always first |
| `logo_search` | Free | Whenever brand logos referenced |
| `21st_magic_component_builder` | Pro | Only on user confirmation, only when no Inspiration match works |
| `21st_magic_component_refiner` | Pro | Only on user confirmation, only when one Inspiration is 80% there |

If quota errors come back: degrade to lift-and-sweep, surface error, do NOT auto-retry.

## Anti-Patterns

- Calling `builder` when Step 2 returned a strong match
- Generating without passing brand tokens
- Writing files without sweep
- Lifting unclear-license components for public-facing surfaces (zaoos.com, thezao.com, bettercallzaal.com) - prefer Magic-generated there
- Mixing Tailwind v3 + v4 syntax
- Touching `community.config.ts` without explicit user request

## Examples

```
/21st sponsor tier pricing card with Bronze/Silver/Gold/Founder for ZAO Stock landing
/21st AI chat input bar with tool indicators for ZOE shell
/21st audio room CTA with live listener count for FISHBOWLZ replacement
/21st refresh /stake hero with token chart placeholder
/21st RSVP button card mobile-first
```

## Failure Modes

| Symptom | Recovery |
|---|---|
| `magic-mcp` not in `/mcp list` | Install: `npx @21st-dev/cli@latest install claude --api-key <key>`, restart |
| Quota error | Surface to user; offer free fallback |
| Non-Tailwind-v4 syntax | Apply Step 5 sweep; ask user to review if still broken |
| Brand tokens ignored | Re-prompt refiner with explicit tokens; manual swap if still off |
| Mobile-first violation | Apply Step 5 restructure; verify with user before commit |

## Memory Hooks

After successful use, suggest saving:
- Top 3 contributor handles whose components fit ZAO -> `feedback_21st_signals.md`
- Patterns that worked -> `feedback_21st_wins.md`
- Patterns that didn't -> `feedback_21st_losses.md`

## Cross-References

- Doc 549 (hub) - decision matrix
- Doc 549a - catalog inventory
- Doc 549b - access patterns + alternatives
- Doc 549c - pricing & licensing
- Doc 549d - other 21st-dev products (1code, sdk)
- `.claude/rules/components.md`
- `.claude/rules/typescript-hygiene.md`
- `community.config.ts` - brand tokens
