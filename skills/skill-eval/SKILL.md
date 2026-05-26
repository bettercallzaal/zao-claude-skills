---
name: skill-eval
description: Evaluate the most recent skill invocation in this session - did the output match the skill's SKILL.md spec? Was the user satisfied? Logs a graded eval to ~/dev/zao-claude-skills/evals/<skill>/YYYY-MM-DD-<slug>.md so iterations are version-tracked alongside the skill. Use when the user types /skill-eval, /eval-skill, /review-skill, or asks "how did that skill do" / "was that skill output good" / "let's grade the last skill use". Also use proactively after surprising or low-quality skill outputs.
allowed-tools: Read Write Edit Bash Skill
---

# /skill-eval - evaluate the last skill output

The feedback loop that improves the ZAO skill library. After any skill runs, this skill grades the output against the skill's own SKILL.md spec, logs to `~/dev/zao-claude-skills/evals/<skill>/YYYY-MM-DD-<slug>.md`, and recommends edits to the skill itself if quality is low.

Lives in the same repo as the skills it evaluates (`bettercallzaal/zao-claude-skills`), so evals + skills evolve together.

## When to fire

- User types `/skill-eval`, `/eval-skill`, `/review-skill`, `/grade-skill`
- "How did that skill do?", "was that output good?", "let's grade the last skill use"
- User says "rerun X, the output was off" - eval first, then rerun

Proactive fire (without user request):
- After a skill output that the user immediately corrected ("no, not that, do Y instead") - that's a quality signal worth logging
- After a skill's first real use - the freshness creates a fast feedback loop

## Phase 1 - Identify which skill to evaluate

Look back in the conversation for the most recent `Skill` tool invocation. Capture:
- `skill_name` (e.g. `meeting`, `zao-research`, `handoff`)
- `args` passed
- `output_summary` - what the skill actually produced (files written, decisions, text)

If multiple skills ran recently, ask the user which one to eval. If none in this session, ask the user to name the skill + paste/point-to the output.

Read the skill's SKILL.md from `~/.claude/skills/<skill_name>/SKILL.md`. The frontmatter's `description` + the body's phases / hard rules / output shape are the rubric.

## Phase 2 - Grade against the rubric

Score on six dimensions (1-5 scale, 5 = excellent):

| Dimension | Question | Scoring |
|-----------|----------|---------|
| **Trigger fit** | Did the skill fire on the right input? Or was it the wrong skill for this user message? | 5 = perfect fit. 1 = wrong tool, should have routed elsewhere. |
| **Output shape** | Does the output match the format the SKILL.md spec'd (sections, files, paths)? | 5 = matches exactly. 1 = ignored the spec. |
| **Completeness** | Did the skill deliver all the artifacts its spec promised? | 5 = all phases ran. 1 = aborted early or skipped sections. |
| **Accuracy** | Are decisions / actions / quotes / numbers correctly extracted from the source? Any hallucinated content? | 5 = nothing made up. 1 = significant fabrication. |
| **Confidence honesty** | Were low-confidence items flagged? Or presented as facts? | 5 = honest about uncertainty. 1 = false confidence. |
| **User satisfaction** | Did the user accept the output, or did they push back / correct / abandon? | 5 = no pushback. 1 = user rejected outright. |

If a dimension is N/A for this skill, skip it. Document why.

Each dimension gets:
- Score (1-5)
- One-line evidence (verbatim quote from output OR observed user reaction)

## Phase 3 - Recommendations

Based on the scores, write 0-5 concrete edits to the skill's SKILL.md, scripts, or references. Voice: imperative, one-line, paste-ready.

Examples:
- `Add to "Hard rules": "Never invent owners. If transcript ambiguous, mark owner=Both + confidence=low."`
- `Phase 4 step "Bonfire push" should check ~/.zao/zao.env as fallback (already patched in doc 754; verify still in place).`
- `Add "When NOT to fire" item: "Skip on conversations under 200 words - too thin to extract structure."`

If no recommendations, write `No edits needed - the skill behaved as spec'd.`

## Phase 4 - Confirm + write the eval

Show the user the draft eval inline:

```
Skill: <name>
Run context: <one-line summary of what user asked + what skill did>
Scores:
  Trigger fit:        N/5 - <evidence>
  Output shape:       N/5 - <evidence>
  Completeness:       N/5 - <evidence>
  Accuracy:           N/5 - <evidence>
  Confidence honesty: N/5 - <evidence>
  User satisfaction:  N/5 - <evidence>
Average:              N.N/5

Recommendations:
1. ...
2. ...
```

Ask: "Confirm + log this eval? (y/n, or edit a score)"

On confirm, write to `~/dev/zao-claude-skills/evals/<skill>/YYYY-MM-DD-<slug>.md` using the template below.

The slug is auto-picked: `<one-word-summary-of-what-the-skill-did>` (e.g. `meeting-craig-batch-may19`, `zao-research-bonfire-config-gap`, `handoff-recursive-test`).

## Phase 5 - Apply recommendations (optional)

If recommendations exist + user wants them applied, ask: "Apply N recommended edits to `~/.claude/skills/<skill>/`?"

On yes: open the skill files, apply the edits. The PostToolUse hook will auto-sync + push to `bettercallzaal/zao-claude-skills`.

On no: just log. The recommendations live in the eval doc for future reference.

## Phase 6 - Report

```
[OK] Eval -> ~/dev/zao-claude-skills/evals/<skill>/YYYY-MM-DD-<slug>.md
[--] Recs - N recommendations logged, user declined to apply  |  [OK] Recs - N edits applied (auto-synced to repo)
[OK] Skill <name> average score: N.N/5

Next /skill-eval will pick up the next skill invocation.
```

## Eval template

The file written to `~/dev/zao-claude-skills/evals/<skill>/YYYY-MM-DD-<slug>.md`:

```markdown
---
skill: <name>
date: YYYY-MM-DD
slug: <slug>
average: N.N
session-context: <one-line - what was happening in the session>
---

# Eval - <skill> - YYYY-MM-DD - <slug>

## Run context
<one-paragraph: what the user asked, what the skill output, why this eval was triggered>

## Scores

| Dimension | Score | Evidence |
|-----------|-------|----------|
| Trigger fit        | N/5 | <quote or observation> |
| Output shape       | N/5 | <quote or observation> |
| Completeness       | N/5 | <quote or observation> |
| Accuracy           | N/5 | <quote or observation> |
| Confidence honesty | N/5 | <quote or observation> |
| User satisfaction  | N/5 | <quote or observation> |
| **Average**        | **N.N/5** | |

## Recommendations
1. <imperative edit to SKILL.md or scripts>
2. ...

## Applied
- [x] Rec 1 - applied YYYY-MM-DD
- [ ] Rec 2 - pending
- [ ] Rec 3 - declined (reason: ...)

## Future eval triggers
- <signal to watch for that would justify the next eval of this skill>
```

## Aggregation - skill quality over time

Each skill's `evals/<skill>/` folder becomes a quality time series. Read the directory listing to see trend. Future v2 features (not in scope here):
- Weekly digest skill that reads all `evals/*/` and ranks skills by trending score
- Auto-PR: when a skill's average drops below 3.5, propose the most-recommended edit

## /autoresearch integration

This skill pairs with `/autoresearch` for iterative skill improvement:
1. Use a skill (e.g. `/meeting`)
2. Run `/skill-eval` - get scores + recommendations
3. Run `/autoresearch` with `iterations: 3` on the skill spec - apply edits, re-test against a fixture, compare scores
4. Keep the highest-scoring version

This makes the skill library a self-improving system, not just a static collection.

## Anti-patterns

- Do NOT auto-fire on EVERY skill invocation - that creates noise. Fire only on triggers in "When to fire" or on user request.
- Do NOT score without evidence. Every dimension's score needs a quote or observation from this session.
- Do NOT lower the average score of "user satisfaction" speculatively. Score 3 (neutral) if no clear signal.
- Do NOT apply recommendations without user confirm - the recommendations may misread the situation.

## References

- `~/dev/zao-claude-skills/evals/README.md` - eval format + directory structure
- `~/dev/zao-claude-skills/README.md` - repo overview
- Doc 755 (in ZAO OS V1) - /handoff design (the sibling pattern for session-level eval)
