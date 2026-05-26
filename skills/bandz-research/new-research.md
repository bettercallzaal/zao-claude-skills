# How to Add New Research

## Step 1: Pick the Next Number

Check the highest numbered folder in `docs/research/` and use the next sequential number. Start at `01` if empty.

```bash
ls docs/research/
```

## Step 2: Create the Folder and README

```bash
mkdir -p docs/research/{number}-{topic-name}
```

## Step 3: Write the README with This Template

```markdown
# {Number} — {Title}

> **Status:** Research complete
> **Date:** {Today's date}
> **Goal:** {One-line description of what this research answers}

---

## Key Decisions / Recommendations

{Table or bullet list of the main takeaways — put these FIRST so readers get value immediately}

---

## {Section 1}

{Research content with tables, code blocks, comparisons}

## {Section 2}

{More content}

---

## Sources

- [Source Name](URL)
- [Source Name](URL)
```

### Rules for Writing Research Docs

1. **Put recommendations/decisions at the top** — readers get the answer in 30 seconds
2. **Use tables** for comparisons, pricing, feature lists
3. **Include specific numbers** — versions, prices, rate limits, dates
4. **Link sources** at the bottom
5. **Keep it actionable** — "here's what to do", not theoretical
6. **Match B&Z Builds' context** — filter findings through: Next.js 16 App Router, Neon/Prisma, NextAuth v5 GitHub OAuth, two-creator split-theme, activity feed aggregation, admin-curated content
7. **Cover both creators** — research must apply to both `bettercallzaal` AND `ohnahji`. Note any differences (e.g. Ohnahji is a music artist on Spotify, bettercallzaal is a listener; bettercallzaal has GitHub activity, Ohnahji may not)
8. **Note rate limits** — API rate limits are critical for feed aggregation planning (fetching for 2 accounts doubles the request count)

## Step 4: Update the Research Index

Add the new doc to `docs/research/README.md` in the appropriate category.

Also update [topics.md](.agents/skills/bandz-research/topics.md) to mark the topic as researched with the doc number.

## Step 5: Commit

```bash
git add docs/research/{number}-{topic}/ docs/research/README.md
git commit -m "docs: {topic} research (doc {number})"
```

## Research Quality Checklist

- [ ] Recommendations/key decisions at the top
- [ ] Specific to B&Z Builds (not generic)
- [ ] API rate limits documented (if applicable)
- [ ] Numbers, versions, and dates included
- [ ] Sources linked
- [ ] Actionable (tells you what to do, not just what exists)
- [ ] Covers both creators where applicable (bettercallzaal + ohnahji)
- [ ] Updated `docs/research/README.md` index
- [ ] Updated `topics.md` to show topic is covered
