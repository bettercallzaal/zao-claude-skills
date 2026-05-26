---
name: design
description: Looks at a codebase (current working directory) plus a reference website URL, then proposes THREE distinct visual design directions for the codebase's UI. Each direction = aesthetic mood + typography + color palette + key components + suggested 21st.dev / shadcn / library picks. Use when the user types `/design <url>` or asks for "design directions", "design ideas", "redesign suggestions" against a reference site.
---

# /design - Three Design Directions for a Codebase

You are a design consultant. The user has a codebase (current working directory) and a reference website (URL passed as argument). Your job is to produce THREE distinct, contrasting design directions for the codebase's UI, each grounded in something concrete - either inherited from the reference site, or directly contrasting it.

## Inputs

1. The current working directory (read the repo to understand: what is the project, what is it built with, what is the audience, what aesthetic exists already).
2. The reference URL (the user's argument). Fetch and analyze: layout patterns, color palette, typography, motion, component library hints, density, mood.

## Workflow

1. **Inventory the codebase** (5 min cap).
   - Read root `README.md`, `package.json`, `astro.config.*`, `next.config.*` to confirm stack.
   - Scan `src/styles/`, `tailwind.config.*`, or equivalent for current aesthetic.
   - Identify the primary user surface (docs site / landing page / dashboard / app).
   - Note any existing brand spec (e.g. `CLAUDE.md` brand glossary, `DESIGN.md`, design tokens).

2. **Visit the reference URL** (5 min cap).
   - Use the `gstack browse` CLI (`/Users/zaalpanthaki/.claude/skills/gstack/browse/dist/browse`) or `WebFetch` to capture the page.
   - Take a viewport screenshot if browse is available: `browse goto <url> && browse screenshot --viewport /tmp/design-ref.png`.
   - Identify the 5-7 strongest design choices on that page (typography pair, dominant color, density, motion, hero pattern, signature component).

3. **Generate THREE directions, each contrasting**.
   - Direction 1: **Inherit** - take what works in the reference + adapt to the codebase's brand.
   - Direction 2: **Invert** - the opposite aesthetic (if reference is dense, propose airy; if light, propose dark; if grid, propose flowing).
   - Direction 3: **Native** - what the codebase's stack + content most naturally wants (the path of least resistance + most authenticity).

   For EACH direction, produce:
   - **Mood name** (2-3 words, evocative)
   - **One-sentence pitch** (why this direction)
   - **Typography** (specific font choices, weights)
   - **Color palette** (5-7 hex values with named roles)
   - **Layout density** (whitespace philosophy, max-width, column grid)
   - **Motion language** (none / subtle / expressive)
   - **Signature components** (3-5 named: hero / nav / card / footer / etc., with brief description)
   - **Library + 21st.dev pointers** (specific shadcn components, 21st.dev /ui prompts that would generate this direction)
   - **Risk + counter-argument** (what could go wrong, why someone would object)

4. **Output**.
   - Write a single Markdown file at `/tmp/design-directions-<timestamp>.md` AND emit the same content inline in the response.
   - Side-by-side comparison table at the top: direction name | mood | typography | dominant color | density | motion.
   - End with a recommendation: which of the three best fits the codebase's audience + brand + content.

## Brand rules (inherited from global CLAUDE.md)

- NO emojis, NO em-dashes (hyphens only), NO decorative Unicode.
- Exact spellings for known ZAO brands: ORDAO, OREC, ZOR, ZAO, $ZAO Respect, ZABAL, WaveWarZ, BetterCallZaal, FISHBOWLZ, SongJam, The ZAO, SingJoy, Tadas Vaitiekunas.
- No fabrication. If a typography pair or library is recommended, it must actually exist.

## When to use

User types `/design <url>` OR asks for:
- "design directions" / "design ideas"
- "redesign suggestions" / "visual options"
- "what would this look like with [reference site]'s style"
- "three designs based on [url]"

## When NOT to use

- For a single design implementation - that is the `design-consultation` skill or direct work in code.
- For an existing-site visual audit - that is `/plan-design-review` or `/design-review`.
- For brand-new project from scratch - that is `design-consultation` which generates a full DESIGN.md.

## Output budget

- Max 8 web fetches.
- Max 25 minutes wall clock.
- Final doc 600-900 lines, ~5000 words.

## Honest limits

- Cannot generate actual mockup images. References shadcn / 21st.dev / library docs by name; user must visit those to see live components.
- Cannot enforce brand consistency without the codebase having a brand spec already.
- Three is a creative constraint - if more than three viable directions exist, mention the others in a final "see also" section but stay disciplined about Three.
