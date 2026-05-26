---
name: fractal
description: Ingest a new fractal-governance resource (URL, repo, person, community, tool) and add it to the ZAOfractal repo in the right place. Handles dedup, frontmatter, source classification, cross-linking, and tracker fires. Use when the user shares a fractal-related URL, says "add this to the fractal repo", drops new Eden Creators / Optimystics / community content, or types `/fractal <input>`.
---

# /fractal - Ingest a New Fractal Resource

You are the curator of the ZAOfractal repo (github.com/ZAODEVZ/ZAOfractal). When the user shares a new fractal-related resource - URL, repo, person, community, tool, paper - you decide WHERE it belongs in the repo, dedup against what is already there, and add it in the right format.

## Inputs

Anything fractal-related:
- A URL (article, repo, video, tweet, dashboard, contract)
- A person name + role
- A community / tool description
- Raw notes the user wants captured

If the user types `/fractal <input>`, the input is everything after the slash. Otherwise, the user just dropped content - infer.

## Where things go (repo map)

```
/Users/zaalpanthaki/Documents/ZAOfractal/
  reference/                shallow survey docs (one per topic, ~1-2 min read)
    01-fractal-democracy-theory.md
    02-fractally-protocol.md
    03-eden-on-eos.md
    04-genesis-fractal.md
    05-eden-fractal.md
    06-optimism-fractal.md
    07-respect-token-mechanics.md
    08-ordao-orec-frapps.md
    09-respect-game-process.md
    10-fractal-communities-directory.md
    11-key-people.md
    12-comparison-vs-traditional-daos.md
    13-related-experiments.md
    14-timeline.md
    15-sources.md
  research/                 DEEP-tier hub docs
    01-foundations-deep.md
    02-live-communities-deep.md
    03-music-cignals-deep.md
    04-async-identity-deep.md
    05-targeted-gap-fillers.md
    06-frapp-gh-prd.md
    code-walk/              fractalbot + ORDAO contracts walkthroughs
    fractal-deep/           full history of each fractal + Optimystics tools survey
      01-eos-fractally-origins.md
      02-eden-fractal-full-history.md
      03-optimism-fractal-full-history.md
      04-optimystics-tools-survey.md
      05-other-fractal-communities.md
      06-adjacent-governance-tooling.md
      07-larimer-essays-academic-bibliography.md
    whitepaper-foundations/ 7 sub-docs for the magnum-opus whitepaper
    primary-sources/        canonical ORDAO + Respect specs
    context/                adjacent governance frames
    external/               cross-cutting research
  whitepaper/               the magnum opus drafts
    draft/ch01-* through ch11-*
  RESOURCES.md              master index of every URL/contract/person/repo
  site/                     the Astro static site (auto-renders all .md)
    src/lib/timeline.ts     hard-coded timeline events (sync with reference/14-timeline.md)
    src/lib/people.ts       hard-coded people cards (sync with reference/11-key-people.md)
```

## Workflow

### Step 1: Classify
Decide what the resource is:
- **Person** -> reference/11-key-people.md + site/src/lib/people.ts entry
- **Community** -> reference/10-fractal-communities-directory.md + research/fractal-deep/05-other-fractal-communities.md if substantial
- **Tool / app / framework** -> research/fractal-deep/04-optimystics-tools-survey.md or research/fractal-deep/06-adjacent-governance-tooling.md depending on builder
- **Contract / on-chain object** -> RESOURCES.md + the relevant existing doc (07-respect-token-mechanics or 08-ordao-orec-frapps)
- **Academic paper / essay** -> research/fractal-deep/07-larimer-essays-academic-bibliography.md or reference/15-sources.md
- **Event / milestone** -> reference/14-timeline.md AND site/src/lib/timeline.ts (the timeline data is duplicated for build-time use)
- **Full new content cluster** (e.g. a whole new garden/blog/portal) -> NEW file at research/fractal-deep/NN-<slug>.md plus updates to relevant existing docs cross-linking back

### Step 2: Dedup
Before writing, search the repo:

```bash
cd /Users/zaalpanthaki/Documents/ZAOfractal
grep -ri "<name or key term>" reference/ research/ RESOURCES.md
```

If a hit found:
- Person already in 11-key-people: append new role / project to their entry, do not duplicate.
- Tool already in tools-survey: extend the section with new info + cite the new source.
- URL already in RESOURCES.md: confirm; do nothing.

### Step 3: Fetch + verify (if URL)
Use the universal fetch ladder (matches zao-research skill Step 4.5):
1. WebFetch
2. exa web_fetch (mcp__plugin_everything-claude-code_exa__web_fetch_exa)
3. Playwright / `/browse` (gstack browse CLI at /Users/zaalpanthaki/.claude/skills/gstack/browse/dist/browse)
4. Wayback Machine

For Reddit / X / Hive / Medium archive: use the `/fetch` skill which routes to the right tool.

Mark every source [FULL] / [PARTIAL - what is missing] / [FAILED - what was tried].

### Step 4: Write
Edit the target file(s). Brand rules:
- NO emojis, NO em-dashes (hyphens only), NO decorative Unicode.
- Exact spellings: ORDAO, OREC, ZOR, $ZAO Respect, Optimystics, SingJoy, Tadas Vaitiekunas, sim31, Daniel Larimer, Fractally, Eden Fractal, Optimism Fractal, ZAO Fractal, Roy Fractal, BetterCallZaal, ZAO OS, FISHBOWLZ, ZABAL, SongJam, COC Concertz, WaveWarZ, NERDDAO, Huottoja.
- No fabrication. Numbers, dates, contract addresses must trace to a source. Unknown -> write UNKNOWN.

### Step 5: Cross-link
If you added a new community, update RESOURCES.md "Fractal Communities" section. If you added a new person, update RESOURCES.md "People" + (if they have a role on the site) site/src/lib/people.ts. If you added a new tool, update RESOURCES.md "Tools / Repos" + (if Optimystics-built) research/fractal-deep/04-optimystics-tools-survey.md.

### Step 6: Build site if data files changed
If you edited site/src/lib/*.ts, rebuild the site to regenerate:

```bash
cd /Users/zaalpanthaki/Documents/ZAOfractal/site && npm run build
```

### Step 7: Commit + push
Conventional commit format. One commit per ingest unless multiple resources from a single batch.

```bash
cd /Users/zaalpanthaki/Documents/ZAOfractal
git add .
git status --short
git commit -m "<message>"
git push
```

Vercel auto-deploys on push (manual `vercel deploy --prod --yes` if auto-deploy is broken; verify by checking https://zaofractal.vercel.app/).

### Step 8: Fire tracker row (optional)
Per the standing rule, if the ingest is substantial (new community, new whitepaper chapter, new full-doc research), fire a tracker task:

```bash
~/bin/zao-tracker fractal-ingest "<short title of what was added>"
```

Skip for small touches (a single URL added to RESOURCES.md, a one-line edit).

## Important constraints

- The site reads the Markdown source directly via Astro content collections (see /Users/zaalpanthaki/Documents/ZAOfractal/site/src/content.config.ts). New `.md` files in reference/ research/ whitepaper/ auto-appear on the site at next build.
- The exception is timeline.ts + people.ts which hard-code data for build-time component generation. Keep these in sync with the canonical Markdown.
- RESOURCES.md is the master index. It is hand-curated, not auto-generated. Keep entries terse, link out to docs for depth.

## When NOT to use

- For research that needs synthesis across many sources -> use /zao-research instead (writes to ZAO OS V1 research library with its own workflow).
- For drafting whitepaper prose -> the whitepaper/draft/ files are direct edits, not ingest work.
- For UI / site changes -> not this skill; edit site/src/ directly.

## When to ASK

- If the user dropped raw content with no clear classification and you would otherwise have to guess: ask "Where does this belong? Reference [shallow] / Research [deep] / new dedicated doc?"
- If multiple matches exist and the right home is ambiguous (e.g. a person who is also a tool maker): ask which to prioritize.
- If the resource appears to be private / sensitive / not-yet-public: confirm before adding to the public repo.

## Output

Always end with:
1. A one-line summary of what was added and where.
2. The diff (git status output) so the user can verify.
3. The Vercel URL where the change is visible (after deploy completes).

## Example

User drops a Medium post about a new Cignals roadmap update.

You:
1. Classify: tool update.
2. Dedup: `grep -ri "Cignals" research/` finds existing coverage in research/fractal-deep/04-optimystics-tools-survey.md + research/03-music-cignals-deep.md.
3. Fetch the Medium URL.
4. Append to research/fractal-deep/04-optimystics-tools-survey.md section "Cignals" with the new ship date + features. Mark source [FULL] with URL.
5. Update RESOURCES.md "Optimystics Tools" subsection with new URL.
6. Site auto-picks up via Astro. No data file changes.
7. Commit "docs: Cignals roadmap update from <date>" + push.
8. Report: "Added Cignals roadmap update to research/fractal-deep/04 + RESOURCES.md. Diff: <git status>. Live at: https://zaofractal.vercel.app/research/fractal-deep/04-optimystics-tools-survey"
