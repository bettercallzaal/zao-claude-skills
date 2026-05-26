# How to Search Existing Research

## Quick Search Commands

Search all research documents for a keyword:
```bash
grep -ri "keyword" docs/research/*/README.md
```

Search for a specific topic across research + docs:
```bash
grep -ri "topic" docs/research/*/README.md docs/superpowers/**/*.md
```

Find which research docs mention a specific service:
```bash
grep -rli "github\|twitter\|youtube\|spotify\|twitch" docs/research/*/README.md
```

## Common Search Patterns

### Find API information
```bash
grep -ri "endpoint\|rate limit\|/v2/\|/api/" docs/research/*/README.md
```

### Find pricing/cost information
```bash
grep -ri "pricing\|cost\|free tier\|\$/mo\|quota" docs/research/*/README.md
```

### Find authentication patterns
```bash
grep -ri "oauth\|token\|scope\|api key\|secret" docs/research/*/README.md
```

### Find implementation patterns
```bash
grep -ri "npm install\|import.*from\|setup\|configuration\|example" docs/research/*/README.md
```

### Find recommendations
```bash
grep -ri "recommend\|best for\|verdict\|use this\|avoid" docs/research/*/README.md
```

## Also Check These Locations

- `docs/superpowers/specs/` — design specs with architecture decisions
- `docs/superpowers/plans/` — implementation plans with technical details
- `CLAUDE.md` — project-specific rules and conventions
- `AGENTS.md` — agent instructions
- `prisma/schema.prisma` — data model (authoritative for DB questions)
- `src/lib/auth.ts` — auth config (authoritative for auth questions)
