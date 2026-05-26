# Quality — Good vs. Bad Patterns

> Extracted from Anthropic's official guide: Chapters 2 & 5.
> These require judgment calls — use the examples to calibrate scoring.

## Description Quality

The description field is the most important part of frontmatter. It's how Claude decides whether to load your skill (first level of progressive disclosure).

### Structure

```
[What it does] + [When to use it] + [Key capabilities]
```

### Good Descriptions

```yaml
# Good - specific and actionable
description: Analyzes Figma design files and generates
developer handoff documentation. Use when user uploads .fig
files, asks for "design specs", "component documentation", or
"design-to-code handoff".

# Good - includes trigger phrases
description: Manages Linear project workflows including sprint
planning, task creation, and status tracking. Use when user
mentions "sprint", "Linear tasks", "project planning", or asks
to "create tickets".

# Good - clear value proposition
description: End-to-end customer onboarding workflow for
PayFlow. Handles account creation, payment setup, and
subscription management. Use when user says "onboard new
customer", "set up subscription", or "create PayFlow account".
```

### Bad Descriptions

```yaml
# Too vague
description: Helps with projects.

# Missing triggers
description: Creates sophisticated multi-page documentation
systems.

# Too technical, no user triggers
description: Implements the Project entity model with
hierarchical relationships.
```

## Instructions Quality

### Recommended Structure

```markdown
---
name: your-skill
description: [...]
---

# Your Skill Name

## Instructions

### Step 1: [First Major Step]
Clear explanation of what happens.
```

### Be Specific and Actionable

Good:

```
Run `python scripts/validate.py --input {filename}` to check
data format.
If validation fails, common issues include:
- Missing required fields (add them to the CSV)
- Invalid date formats (use YYYY-MM-DD)
```

Bad:

```
Validate the data before proceeding.
```

### Include Error Handling

```markdown
## Common Issues

### MCP Connection Failed
If you see "Connection refused":
1. Verify MCP server is running: Check Settings > Extensions
2. Confirm API key is valid
3. Try reconnecting: Settings > Extensions > [Your Service] > Reconnect
```

### Reference Bundled Resources Clearly

```markdown
Before writing queries, consult `references/api-patterns.md`
for:
- Rate limiting guidance
- Pagination patterns
- Error codes and handling
```

### Use Progressive Disclosure

Keep SKILL.md focused on core instructions. Move detailed documentation to `references/` and link to it.

## Skill Use Case Categories

### Category 1: Document & Asset Creation

Creating consistent, high-quality output (documents, presentations, apps, designs, code).

**Key techniques:**
- Embedded style guides and brand standards
- Template structures for consistent output
- Quality checklists before finalizing
- No external tools required — uses Claude's built-in capabilities

### Category 2: Workflow Automation

Multi-step processes that benefit from consistent methodology, including coordination across multiple MCP servers.

**Key techniques:**
- Step-by-step workflow with validation gates
- Templates for common structures
- Built-in review and improvement suggestions
- Iterative refinement loops

### Category 3: MCP Enhancement

Workflow guidance to enhance the tool access an MCP server provides.

**Key techniques:**
- Coordinates multiple MCP calls in sequence
- Embeds domain expertise
- Provides context users would otherwise need to specify
- Error handling for common MCP issues

## Skill Patterns

### Problem-first vs. Tool-first

- **Problem-first:** "I need to set up a project workspace" — skill orchestrates the right tools in the right sequence. Users describe outcomes; the skill handles the tools.
- **Tool-first:** "I have Notion MCP connected" — skill teaches Claude the optimal workflows and best practices. Users have access; the skill provides expertise.

### Pattern 1: Sequential Workflow Orchestration

**Use when:** Multi-step processes in a specific order.

**Key techniques:**
- Explicit step ordering
- Dependencies between steps
- Validation at each stage
- Rollback instructions for failures

### Pattern 2: Multi-MCP Coordination

**Use when:** Workflows span multiple services.

**Key techniques:**
- Clear phase separation
- Data passing between MCPs
- Validation before moving to next phase
- Centralized error handling

### Pattern 3: Iterative Refinement

**Use when:** Output quality improves with iteration.

**Key techniques:**
- Explicit quality criteria
- Iterative improvement
- Validation scripts
- Know when to stop iterating

### Pattern 4: Context-Aware Tool Selection

**Use when:** Same outcome, different tools depending on context.

**Key techniques:**
- Clear decision criteria
- Fallback options
- Transparency about choices

### Pattern 5: Domain-Specific Intelligence

**Use when:** Skill adds specialized knowledge beyond tool access.

**Key techniques:**
- Domain expertise embedded in logic
- Compliance before action
- Comprehensive documentation
- Clear governance

## Success Criteria

### Quantitative Metrics

- Skill triggers on 90% of relevant queries
  - *How to measure:* Run 10-20 test queries. Track auto-load vs. manual invocation.
- Completes workflow in X tool calls
  - *How to measure:* Compare with/without skill. Count tool calls and tokens.
- 0 failed API calls per workflow
  - *How to measure:* Monitor MCP server logs. Track retry rates and error codes.

### Qualitative Metrics

- Users don't need to prompt Claude about next steps
- Workflows complete without user correction
- Consistent results across sessions
