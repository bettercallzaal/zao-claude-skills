# Anti-Patterns — Known Failure Modes

> Extracted from Anthropic's official guide: Chapters 3 & 5.
> Use these as a checklist: "Does this skill exhibit any of these failure modes?"

## Triggering Failures

### Undertriggering

**Symptom:** Skill never loads automatically.

**Signals:**
- Users have to manually invoke the skill
- Support questions about "when does this activate?"
- Skill description is too generic or too technical

**Root causes:**
- Description too vague: "Helps with projects" won't work
- Missing trigger phrases users would actually say
- Missing relevant file types
- Too technical without user-facing language

**Fix:** Add more detail and nuance to the description — include keywords, particularly for technical terms.

**Debugging approach:** Ask Claude: "When would you use the [skill name] skill?" Claude will quote the description back. Adjust based on what's missing.

### Overtriggering

**Symptom:** Skill loads for unrelated queries.

**Signals:**
- Users disabling the skill
- Confusion about the skill's purpose
- Loads on tangentially related topics

**Fixes:**

1. **Add negative triggers:**
```yaml
description: Advanced data analysis for CSV files. Use for
statistical modeling, regression, clustering. Do NOT use for
simple data exploration (use data-viz skill instead).
```

2. **Be more specific:**
```yaml
# Too broad
description: Processes documents

# More specific
description: Processes PDF legal documents for contract review
```

3. **Clarify scope:**
```yaml
description: PayFlow payment processing for e-commerce. Use
specifically for online payment workflows, not for general
financial queries.
```

## Instruction Failures

### Instructions Not Followed

**Symptom:** Skill loads but Claude doesn't follow instructions.

**Cause 1: Instructions too verbose**
- Keep instructions concise
- Use bullet points and numbered lists
- Move detailed reference to separate files

**Cause 2: Instructions buried**
- Put critical instructions at the top
- Use `## Important` or `## Critical` headers
- Repeat key points if needed

**Cause 3: Ambiguous language**

Bad:
```markdown
Make sure to validate things properly
```

Good:
```markdown
CRITICAL: Before calling create_project, verify:
- Project name is non-empty
- At least one team member assigned
- Start date is not in the past
```

**Cause 4: Model laziness**
Add explicit encouragement:
```markdown
## Performance Notes
- Take your time to do this thoroughly
- Quality is more important than speed
- Do not skip validation steps
```

Note: Adding this to user prompts is more effective than in SKILL.md.

**Advanced technique:** For critical validations, consider bundling a script that performs the checks programmatically rather than relying on language instructions. Code is deterministic; language interpretation isn't.

### MCP Connection Issues

**Symptom:** Skill loads but MCP calls fail.

**Checklist:**
1. **Verify MCP server is connected**
   - Claude.ai: Settings > Extensions > [Your Service]
   - Should show "Connected" status

2. **Check authentication**
   - API keys valid and not expired
   - Proper permissions/scopes granted
   - OAuth tokens refreshed

3. **Test MCP independently**
   - Ask Claude to call MCP directly (without skill)
   - "Use [Service] MCP to fetch my projects"
   - If this fails, issue is MCP not skill

4. **Verify tool names**
   - Skill references correct MCP tool names
   - Check MCP server documentation
   - Tool names are case-sensitive

## Upload Failures

### "Could not find SKILL.md in uploaded folder"
- Cause: File not named exactly SKILL.md
- Solution: Rename to SKILL.md (case-sensitive)
- Verify with: `ls -la` should show SKILL.md

### "Invalid frontmatter"
- Cause: YAML formatting issue

Common mistakes:
```yaml
# Wrong - missing delimiters
name: my-skill
description: Does things

# Wrong - unclosed quotes
name: my-skill
description: "Does things

# Correct
---
name: my-skill
description: Does things
---
```

### "Invalid skill name"
- Cause: Name has spaces or capitals

```yaml
# Wrong
name: My Cool Skill

# Correct
name: my-cool-skill
```

## Context & Performance Failures

### Large Context Issues

**Symptom:** Skill seems slow or responses degraded.

**Causes:**
- Skill content too large
- Too many skills enabled simultaneously
- All content loaded instead of progressive disclosure

**Solutions:**
1. **Optimize SKILL.md size**
   - Move detailed docs to references/
   - Link to references instead of inline
   - Keep SKILL.md under 5,000 words

2. **Reduce enabled skills**
   - Evaluate if more than 20-50 skills enabled simultaneously
   - Recommend selective enablement
   - Consider skill "packs" for related capabilities

## Testing Approach

### Triggering Tests

**Goal:** Ensure your skill loads at the right times.

Example test suite:
```
Should trigger:
- "Help me set up a new ProjectHub workspace"
- "I need to create a project in ProjectHub"
- "Initialize a ProjectHub project for Q4 planning"

Should NOT trigger:
- "What's the weather in San Francisco?"
- "Help me write Python code"
- "Create a spreadsheet" (unless skill handles sheets)
```

### Functional Tests

**Goal:** Verify the skill produces correct outputs.

```
Test: Create project with 5 tasks
Given: Project name "Q4 Planning", 5 task descriptions
When: Skill executes workflow
Then:
    - Project created in ProjectHub
    - 5 tasks created with correct properties
    - All tasks linked to project
    - No API errors
```

### Performance Comparison

**Goal:** Prove the skill improves results vs. baseline.

```
Without skill:
- User provides instructions each time
- 15 back-and-forth messages
- 3 failed API calls requiring retry
- 12,000 tokens consumed

With skill:
- Automatic workflow execution
- 2 clarifying questions only
- 0 failed API calls
- 6,000 tokens consumed
```

## Iteration Signals

Skills are living documents. Watch for these signals:

| Signal | Direction | Action |
|--------|-----------|--------|
| Skill doesn't load when it should | Undertriggering | Add trigger phrases to description |
| Users manually enabling it | Undertriggering | Add keywords and natural language triggers |
| Skill loads for unrelated queries | Overtriggering | Add negative triggers, narrow scope |
| Users disabling it | Overtriggering | Be more specific in description |
| Inconsistent results | Instruction quality | Improve specificity, add validation |
| API call failures | MCP/integration issue | Add error handling, verify tool names |
| User corrections needed | Instruction quality | Make instructions more explicit |
