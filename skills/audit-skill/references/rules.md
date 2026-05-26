# Rules — Hard Requirements for Skills

> Extracted from Anthropic's official guide: Chapters 1 & 2, Reference A.
> These are mechanical pass/fail checks — no judgment calls needed.

## Skill Structure

A skill is a folder containing:

- **SKILL.md** (required): Instructions in Markdown with YAML frontmatter
- **scripts/** (optional): Executable code (Python, Bash, etc.)
- **references/** (optional): Documentation loaded as needed
- **assets/** (optional): Templates, fonts, icons used in output

```
your-skill-name/
├── SKILL.md
├── scripts/
├── references/
└── assets/
```

### SKILL.md Naming

- Must be exactly `SKILL.md` (case-sensitive)
- No variations accepted (SKILL.MD, skill.md, Skill.md, etc.)

### Folder Naming

- Use kebab-case: `notion-project-setup`
- No spaces: ~~`Notion Project Setup`~~
- No underscores: ~~`notion_project_setup`~~
- No capitals: ~~`NotionProjectSetup`~~

### No README.md

- Don't include README.md inside your skill folder
- All documentation goes in SKILL.md or references/
- Repo-level README is fine (for human visitors), but not inside the skill folder

## YAML Frontmatter

The YAML frontmatter is how Claude decides whether to load your skill.

### Minimal Required Format

```yaml
---
name: your-skill-name
description: What it does. Use when user asks to [specific phrases].
---
```

### Field Requirements

**name** (required):
- kebab-case only
- No spaces or capitals
- Should match folder name

**description** (required):
- MUST include BOTH: what it does AND when to use it (trigger conditions)
- Under 1024 characters
- No XML tags (`<` or `>`)
- Include specific tasks users might say
- Mention file types if relevant

**license** (optional):
- Use if making skill open source
- Common: MIT, Apache-2.0

**compatibility** (optional):
- 1-500 characters
- Indicates environment requirements

**metadata** (optional):
- Any custom key-value pairs
- Suggested: author, version, mcp-server
- Example:
  ```yaml
  metadata:
      author: ProjectHub
      version: 1.0.0
      mcp-server: projecthub
  ```

### Security Restrictions

**Forbidden in frontmatter:**
- XML angle brackets (`<` `>`)
- Skills with "claude" or "anthropic" in name (reserved)

**Why:** Frontmatter appears in Claude's system prompt. Malicious content could inject instructions.

## Core Design Principles

### Progressive Disclosure

Skills use a three-level system:

- **First level (YAML frontmatter):** Always loaded in Claude's system prompt. Provides just enough information for Claude to know when each skill should be used without loading all of it into context.
- **Second level (SKILL.md body):** Loaded when Claude thinks the skill is relevant to the current task. Contains the full instructions and guidance.
- **Third level (Linked files):** Additional files bundled within the skill directory that Claude can choose to navigate and discover only as needed.

### Composability

Claude can load multiple skills simultaneously. Your skill should work well alongside others, not assume it's the only capability available.

### Portability

Skills work identically across Claude.ai, Claude Code, and API. Create a skill once and it works across all surfaces without modification, provided the environment supports any dependencies the skill requires.

## Size Limits

- SKILL.md: aim for under ~5,000 words
- 5,000–8,000 words: WARN territory
- Over 8,000 words: likely too large — split into references/
- Move detailed documentation to references/ and link to it

## Quick Checklist (Reference A)

### During development

- [ ] Folder named in kebab-case
- [ ] SKILL.md file exists (exact spelling)
- [ ] YAML frontmatter has `---` delimiters
- [ ] name field: kebab-case, no spaces, no capitals
- [ ] description includes WHAT and WHEN
- [ ] No XML tags (`<` `>`) anywhere
- [ ] Instructions are clear and actionable
- [ ] Error handling included
- [ ] Examples provided
- [ ] References clearly linked
