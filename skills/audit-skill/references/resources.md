# Resources — External References

> From Anthropic's official guide: Chapters 4 & 6.
> Use for further reading, edge cases, or when the human asks for links.

## Official Anthropic Documentation

| Resource | Description |
|----------|-------------|
| [Skills Documentation](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/skills) | Primary skill docs |
| [Best Practices Guide](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/skills#best-practices) | Official best practices |
| [API Reference](https://docs.anthropic.com/en/api) | Claude API docs |
| [MCP Documentation](https://modelcontextprotocol.io) | Model Context Protocol spec |

## Blog Posts & Articles

| Resource | Description |
|----------|-------------|
| Introducing Agent Skills | Launch announcement |
| Equipping Agents for the Real World | Engineering blog on skills architecture |
| Skills Explained | Overview of how skills work |
| How to Create Skills for Claude | Step-by-step creation guide |
| Building Skills for Claude Code | Claude Code-specific guidance |
| Improving Frontend Design through Skills | Case study: frontend-design skill |

## Example Skills

| Resource | Description |
|----------|-------------|
| [anthropics/skills](https://github.com/anthropics/skills) | Public skills repository with Anthropic-created skills |

## Tools

| Tool | Description |
|------|-------------|
| skill-creator | Built into Claude.ai and available for Claude Code. Generates skills from descriptions, reviews existing skills, suggests improvements. Use: "Help me build a skill using skill-creator" |

## Skills API

For programmatic use cases (building applications, agents, automated workflows):

- `/v1/skills` endpoint for listing and managing skills
- `container.skills` parameter in Messages API requests
- Version control via Claude Console
- Works with Claude Agent SDK for custom agents

**Note:** Skills in the API require the Code Execution Tool beta.

| Use Case | Best Surface |
|----------|-------------|
| End users interacting directly | Claude.ai / Claude Code |
| Manual testing during development | Claude.ai / Claude Code |
| Individual, ad-hoc workflows | Claude.ai / Claude Code |
| Applications using skills programmatically | API |
| Production deployments at scale | API |
| Automated pipelines and agent systems | API |

## Distribution

### Current Model (January 2026)

**Individual users:**
1. Download the skill folder
2. Zip the folder (if needed)
3. Upload to Claude.ai via Settings > Capabilities > Skills
4. Or place in Claude Code skills directory

**Organization-level:**
- Admins can deploy skills workspace-wide (shipped December 18, 2025)
- Automatic updates
- Centralized management

### Agent Skills Open Standard

Skills are published as an open standard (like MCP). Portable across tools and platforms. Use the `compatibility` field for platform-specific capabilities.

### GitHub Distribution

1. Host on GitHub with public repo, clear README, example usage
2. Link from MCP documentation
3. Provide quick-start installation guide

## Getting Support

| Channel | Use For |
|---------|---------|
| Claude Developers Discord | General technical questions |
| [anthropics/skills/issues](https://github.com/anthropics/skills/issues) | Bug reports (include: skill name, error message, steps to reproduce) |
