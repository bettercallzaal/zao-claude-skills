---
name: audit-skill
description: Audit Claude skills against Anthropic's official best practices. Use when asked to audit, review, evaluate, or improve skill quality. Accepts a skill name, path, or "all" to audit every skill found.
user-invocable: true
allowed-tools: Read, Edit, Glob, Grep, Task
argument-hint: "<skill-name|path|all>"
---

# Skill Auditor

Audit Claude skills against best practices from Anthropic's official guide.

## References

Bundled reference files, split by audit concern:

| File | Contains | Use for |
|------|----------|---------|
| `references/rules.md` | Hard requirements: naming, frontmatter format, size limits, security | Structure & Frontmatter checks |
| `references/quality.md` | Good/bad examples, patterns, success criteria | Description, Instructions, & Disclosure checks |
| `references/anti-patterns.md` | Known failure modes, troubleshooting, iteration signals | Cross-cutting "does this skill exhibit any known problems?" |
| `references/resources.md` | External links, API docs, distribution guidance | Further reading, edge cases, or when user asks for links |

## Finding Skills

Search the project for all skills:

```
**/.claude/skills/*/SKILL.md
```

When given a name like `foo`, resolve by searching for a folder named `foo` containing `SKILL.md`. When given a path, use it directly. When given `all`, audit every `SKILL.md` found (excluding this skill itself).

## Audit Checklist

For each skill, evaluate these categories. Score each check as **PASS**, **WARN**, or **FAIL**.

### 1. Structure

Reference: `references/rules.md`

| Check | PASS | FAIL |
|-------|------|------|
| File is named exactly `SKILL.md` (case-sensitive) | Yes | Any variation |
| Folder is kebab-case (no spaces, capitals, underscores) | Correct | Violates convention |
| No `README.md` inside the skill folder | Absent | Present |
| YAML frontmatter has `---` delimiters on both sides | Yes | Missing or malformed |

### 2. Frontmatter Fields

Reference: `references/rules.md`

| Check | PASS | FAIL |
|-------|------|------|
| `name` field exists and is kebab-case | Yes | Missing or wrong format |
| `name` matches the folder name | Yes | Mismatch |
| `description` field exists | Yes | Missing |
| `description` explains WHAT it does | Clear purpose stated | Vague or absent |
| `description` explains WHEN to use it (trigger conditions) | Trigger phrases present | No triggers |
| `description` is under 1024 characters | Yes | Too long |
| No XML angle brackets in frontmatter values | Clean | Contains `<` or `>` |
| No "claude" or "anthropic" in the name field | Clean | Reserved word used |

### 3. Description Quality

Reference: `references/quality.md` (good/bad examples)

- **Specific and actionable** — Names concrete tasks, file types, or user phrases
- **Includes natural trigger phrases** — Matches how users actually talk
- **Clear value proposition** — The outcome is obvious from reading it
- **Not too vague** — "Helps with projects" = FAIL
- **Not too technical without triggers** — Pure jargon with no user-facing phrases = WARN
- **Negative triggers if broad scope** — Clarifies what it should NOT be used for (WARN if scope is broad and this is missing)

### 4. Instructions Quality

Reference: `references/quality.md` (instruction patterns), `references/anti-patterns.md` (instruction failures)

| Check | PASS | WARN | FAIL |
|-------|------|------|------|
| Step-by-step structure | Numbered/ordered steps | Partially structured | Wall of text |
| Commands are specific and actionable | Exact commands with arguments | Somewhat specific | "Validate things properly" |
| Error handling included | Common errors with solutions | Brief mention | None |
| Examples provided | Concrete usage scenarios | Minimal examples | None |
| File/resource references are explicit | Exact paths or patterns | Some paths | Vague references |

### 5. Progressive Disclosure

Reference: `references/rules.md` (three-level system), `references/quality.md` (recommended structure)

| Check | PASS | WARN | FAIL |
|-------|------|------|------|
| SKILL.md stays focused on core instructions | Yes | Somewhat bloated | Everything crammed in |
| Detailed docs in `references/` when needed | Yes or N/A | Could benefit from splitting | Massive monolithic file |
| Critical instructions appear near the top | Yes | Buried but findable | Key info at the bottom |
| Estimated size under ~5,000 words | Yes | 5,000-8,000 | Over 8,000 |

### 6. Composability

Reference: `references/rules.md` (design principles)

| Check | PASS | WARN |
|-------|------|------|
| No global assumptions (works alongside other skills) | Yes | Assumes exclusive control |
| Tool permissions scoped to what's needed | Minimal set | Overly broad |

### 7. Enhancement Scan (optional, not scored)

After the 6 scored categories, check whether the skill could benefit from patterns documented in `references/quality.md` that it doesn't yet use. Match signals from the skill against the pattern table below and include any hits in the output.

| Signal in the skill | Pattern to suggest | What it adds |
|---------------------|--------------------|--------------|
| Manages a catalog, registry, or list that others contribute to | **Iterative Refinement** — self-updating catalog | Catalog grows organically as new entries are discovered during normal work |
| Orchestrates multi-step workflows (build, deploy, sync) | **Sequential Workflow with validation gates** | Explicit checkpoints between steps; rollback on failure |
| Uses multiple MCP tools or external APIs | **Multi-MCP Coordination** — error handling + retry | Graceful degradation when one service is down |
| Broad scope but no negative triggers in description | **Scope clarification** — negative triggers | Reduces overtriggering on unrelated queries |
| Growing past ~3,000 words with no `references/` directory | **Progressive disclosure** — split into `references/` | Keeps SKILL.md focused; details available on demand |
| References external APIs without verifying them | **Script-based validation** — bundled check script | Deterministic verification instead of relying on language instructions |
| Makes decisions based on context (platform, chain, mode) | **Context-Aware Tool Selection** — decision criteria | Transparent about why one path was chosen over another |
| Embeds domain expertise (gotchas, patterns, conventions) | **Domain-Specific Intelligence** — compliance checks | Pre-action verification against domain rules |

Only include patterns that are clearly relevant — don't force-fit. If no patterns apply, omit this section from the output.

## Output Format

For each skill:

```
## <Skill Name>

**Path:** `path/to/SKILL.md`
**Overall: X/6 categories passing**

| Category | Score | Notes |
|----------|-------|-------|
| Structure | PASS | |
| Frontmatter | PASS | |
| Description Quality | WARN | Missing trigger phrases |
| Instructions | PASS | |
| Progressive Disclosure | PASS | ~180 lines |
| Composability | PASS | |

### Recommendations
1. **Description**: Add trigger phrases — e.g. "Use when user asks to ..."
2. ...

### Strengths
- Excellent step-by-step instructions with error handling
- ...

### Enhancement Opportunities (if any)
- **Iterative Refinement**: This skill manages a catalog that could self-update when ...
```

When auditing multiple skills, end with a summary table:

```
## Summary

| Skill | Structure | Frontmatter | Description | Instructions | Disclosure | Composability |
|-------|-----------|-------------|-------------|--------------|------------|---------------|
| foo   | PASS      | PASS        | WARN        | PASS         | PASS       | PASS          |
| bar   | PASS      | FAIL        | PASS        | WARN         | PASS       | PASS          |
```

## Procedure

### Single skill audit

1. **Load references** — Read `references/rules.md`, `references/quality.md`, and `references/anti-patterns.md`.
2. **Resolve target** — Find the skill from the argument (name search or direct path).
3. **Audit:**
   a. Read the full `SKILL.md`.
   b. Check folder contents — look for `README.md`, `references/`, `scripts/`, `assets/`.
   c. Spot-check 3-5 file paths mentioned in the skill to verify they exist.
   d. Run every check in the Audit Checklist (categories 1-6).
   e. Run the Enhancement Scan (category 7) — match the skill against the pattern table.
   f. Produce structured output per the format above.
4. **Be specific** — Quote the exact line or value that causes a WARN/FAIL.
5. **Offer to fix** — If any category scored WARN or FAIL, ask the user if they'd like the issues fixed. If they accept, apply the recommended changes directly to the SKILL.md file, then re-audit to confirm the fixes brought it to 6/6. If all categories are PASS, skip this step.

### Auditing "all" (parallel strategy)

When auditing all skills, use subagents to parallelize:

1. **Discover** — Glob for all `**/.claude/skills/*/SKILL.md` files. Exclude `audit-skill` itself.
2. **Spawn subagents** — Launch one Task (subagent_type: general-purpose) per skill. Each subagent receives:
   - The path to the SKILL.md to audit
   - The paths to all three reference files (rules.md, quality.md, anti-patterns.md) in this skill's directory
   - Instructions to read the references, then audit the skill, then return the structured output
3. **Aggregate** — Collect all subagent results and compile the summary table.

Subagent prompt template:

```
Audit the skill at `{skill_path}` against Anthropic's official best practices.

1. Read these reference files for audit criteria:
   - `{audit_skill_dir}/references/rules.md`
   - `{audit_skill_dir}/references/quality.md`
   - `{audit_skill_dir}/references/anti-patterns.md`

2. Read the skill at `{skill_path}`.

3. Check the skill's folder contents (README.md, references/, etc.).

4. Spot-check 3-5 file paths mentioned in the skill.

5. Score each category (Structure, Frontmatter, Description Quality,
   Instructions, Progressive Disclosure, Composability) as PASS/WARN/FAIL.

6. Run the Enhancement Scan (category 7) — match the skill's characteristics
   against the pattern table and note any applicable patterns.

7. Return the structured audit output with the results table,
   recommendations, strengths, and enhancement opportunities.
```
