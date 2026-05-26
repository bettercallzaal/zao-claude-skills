---
name: bandz-research
version: 1.0.0
description: |
  Use when researching a topic for B&Z Builds — check existing research library first,
  then conduct new research on platform APIs, embeds, integrations, or infrastructure
  relevant to the project. Use when asked to "research", "look up", or "find out about"
  any API, tool, or pattern for this project.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - Agent
---

# B&Z Builds Research Skill

Use this skill when asked to research a topic for B&Z Builds, find information in existing research, or add new research to the library.

## How to Use

When the user asks to research something:

1. **First check existing research** — search `docs/research/` before doing new research
2. **Conduct new research** if the topic isn't covered — use web search, fetch docs, analyze code
3. **Save findings** in the standardized format at `docs/research/{number}-{topic}/README.md`
4. **Update the index** at `docs/research/README.md` with the new document

## Research Library Location

All research lives in `docs/research/` with numbered folders. See the index at `docs/research/README.md`.

## Existing Research by Topic

See [topics.md](./topics.md) for what's already been researched, organized by category.

## How to Search Existing Research

```bash
grep -ri "keyword" docs/research/*/README.md
```

For topic-specific searches see [search-patterns.md](./search-patterns.md).

## How to Add New Research

See [new-research.md](./new-research.md) for the template and process.

## Project Context

See [project-context.md](./project-context.md) for the tech stack, architecture, and what the research supports.
