# zao-claude-skills

Hand-written Claude Code skills for The ZAO ecosystem - meeting capture, research, distribution, the ZAO bot fleet, the cowork tracker, and more. Sync these into `~/.claude/skills/` on any Mac to inherit the full ZAO operating style.

Maintained by [bettercallzaal](https://github.com/bettercallzaal) - skills evolve daily, build-in-public.

## What is in here

| Category | Skills |
|----------|--------|
| **Session ops** | `handoff`, `meeting`, `capture`, `worksession`, `morning`, `reflect`, `retro`, `z` |
| **Research** | `zao-research`, `bcz-research`, `bandz-research`, `last30days`, `autoresearch` |
| **Distribution** | `socials`, `newsletter`, `clipboard`, `bonfire`, `inbox` |
| **Web3 / ZAO** | `vps`, `coworkvps`, `fractal`, `zabal-games-context`, `fishbowlz`, `big-win` |
| **Dev workflow** | `ship`, `qa`, `qa-only`, `review`, `verify`, `investigate`, `document-release` |
| **Browser / QA** | `browse`, `gstack-upgrade`, `setup-browser-cookies` |
| **Content** | `bcz-yapz-description`, `humanizer`, `onepager`, `21st`, `design`, `design-review`, `design-consultation`, `plan-design-review` |
| **Planning** | `plan-ceo-review`, `plan-eng-review`, `office-hours`, `find-skills`, `audit-skill` |
| **Safety modes** | `careful`, `freeze`, `unfreeze`, `guard` |
| **Personal flows** | `start`, `end` (hours log), `ask-gpt`, `codex`, `fetch`, `reddit-fetch` |
| **Misc** | `cold-outreach`, `graphify`, `quad`, `supabase`, `supabase-postgres-best-practices` |

51 skills total. See `skills/*/SKILL.md` for the full doc on each.

## Installation (new Mac)

```bash
# Clone
git clone https://github.com/bettercallzaal/zao-claude-skills.git ~/dev/zao-claude-skills

# Symlink the sync wrapper
ln -sf ~/dev/zao-claude-skills/bin/zao-skills-sync ~/bin/zao-skills-sync

# Pull all skills into ~/.claude/skills/
zao-skills-sync pull
```

That's it - next time Claude Code reloads its skill list, all 51 skills are available globally.

## Daily flow

```bash
# After editing a skill in ~/.claude/skills/<name>/
zao-skills-sync push                   # rsyncs ~/.claude/skills/* -> ~/dev/zao-claude-skills/skills/*
cd ~/dev/zao-claude-skills
git add -A && git commit -m "..." && git push

# Or sync just one skill
zao-skills-sync push handoff
```

```bash
# To see what changed since last push
zao-skills-sync diff                   # diffs every tracked skill
zao-skills-sync diff handoff           # diffs one
```

```bash
# On another machine, pull updates
cd ~/dev/zao-claude-skills && git pull
zao-skills-sync pull                   # rsyncs repo skills into live ~/.claude/skills/
```

## What is NOT in here

- **Vendored plugins** (`everything-claude-code`, `superpowers`, `oh-my-mermaid`, `caveman`) - those install via Claude Code's plugin system from their own upstreams.
- **Skills that ship as their own git repo** (e.g. `gstack`) - those are cloned directly from their upstream.
- **Secrets / env files** - skills reference `~/.zao/zao.env`, `~/.config/last30days/.env`, and similar paths; the env files themselves are NEVER committed.
- **Hooks, settings, keybindings** - those live in `~/.claude/settings.json` + `~/.claude/keybindings.json` and are personal config, not skills.

## Local env hooks (per-skill, not in this repo)

Several skills assume env vars that live in `~/.zao/zao.env` (chmod 600 on your Mac). If you fork this repo, you'll need to create your own `~/.zao/zao.env` with the keys the skills reference. Common ones:

- `BONFIRE_API_KEY` + `BONFIRE_ID` - for `/bonfire`, `/meeting` (Bonfire push)
- `ZABAL_BONFIRE_AGENT_ID` + `ZABAL_BONFIRE_ERC8004_ID` - for Bonfire graph queries
- `SUPABASE_URL` + `SUPABASE_SERVICE_KEY` - for cowork tracker integration
- `SCRAPECREATORS_API_KEY` - for `/last30days` social-platform fetches
- `AIRTABLE_CRM_TOKEN` + `AIRTABLE_CRM_BASE_ID` - for the ZAO CRM AGENTIC Airtable writes

The skills handle "env missing" gracefully (skip with a clear message), so absence of any var just turns off the corresponding feature.

## Skill structure conventions

Each skill follows the Claude Code skill format:

```
skills/<name>/
  SKILL.md              # frontmatter (name, description, allowed-tools) + the prompt
  scripts/              # bash / python helpers the skill invokes
  references/           # static reference docs the skill links to
  evals/                # optional regression fixtures
```

The `description` field in SKILL.md frontmatter is the trigger - the model uses it to decide whether to fire the skill on a given user message.

## Branding + glossary

These skills assume the canonical spellings from the ZAO brand glossary:
WaveWarZ, COC Concertz, The ZAO, BetterCallZaal, Joseph Goats, Huöttöja, SongJam, ZABAL, SANG, ZOE, ZOLs, FISHBOWLZ, Stilo World, Magnetiq, Restream, Cal.com, Lu.ma. Do not auto-correct.

## License

MIT - take what is useful, fork it, build your own.

## Contributing

PRs welcome. Skills are designed to be ZAO-shaped first but most are useful for any agent-driven Web3 community. Open an issue or PR with the diff + a one-line "why this helps."
