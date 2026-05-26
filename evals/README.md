# evals/

Per-skill quality time series. Each subdir holds graded evals of one skill, written by `/skill-eval` after a real run.

```
evals/
  meeting/
    2026-05-25-craig-batch-may19.md
    2026-05-25-handoff-test.md
    ...
  zao-research/
    2026-05-26-bonfire-config-gap.md
    ...
  handoff/
    2026-05-26-recursive-test.md
    ...
```

## Eval format

Each eval = one markdown file, frontmatter + body. See `/skill-eval` SKILL.md for the canonical template.

Six dimensions, 1-5 scale each, average score in frontmatter for fast trend-reading:

- **Trigger fit** - did the skill fire on the right input?
- **Output shape** - matches the SKILL.md spec'd format?
- **Completeness** - all phases ran?
- **Accuracy** - no hallucinations?
- **Confidence honesty** - low-confidence items flagged?
- **User satisfaction** - did the user accept the output?

## How to read evals

```bash
# Latest eval for a skill
ls -t evals/meeting/ | head -1

# All evals scored below 3.5 (skill needs work)
grep -lE '^average: [0-3]\.' evals/*/*.md

# How a skill trends over time
for f in evals/handoff/*.md; do
  grep -E '^date:|^average:' "$f"
done
```

## Triggers

`/skill-eval` runs manually. Use after:
- A skill output you want to grade
- A skill output you corrected ("no, not that")
- A skill's first real fire (fast feedback loop)
- Before a `/autoresearch` iteration loop on a skill's spec

## Iteration loop

```
1. Use a skill -> output
2. /skill-eval -> scores + recommendations
3. Apply edits to SKILL.md
4. Re-run on a fixture
5. /skill-eval again -> compare scores
6. Keep the highest-scoring version
```

Result: skills get better, measurably.
