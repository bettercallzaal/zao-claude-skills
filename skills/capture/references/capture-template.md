# Capture Doc Template

Use this for `research/captures/NNN-<slug>/README.md`. Modeled on doc 753 (the case that spawned this skill).

---

```markdown
---
topic: <events|community|dev-workflows|business|...>
type: content-capture
status: research-complete
last-validated: YYYY-MM-DD
related-docs: ""
original-query: "<verbatim command Zaal typed - e.g. '/capture <path>' or '/capture <url>'>"
tier: QUICK
captured-from: "<platform> - @<creator> - '<title>'"
source-url: "<url or 'local file at <path>'>"
recording-context: "<one line: what tabs were open, what mode Zaal was in, why captured>"
---

# {NNN} - {Framework Name} ({Creator} {SourceType} capture)

> **Goal:** Capture the {framework name} from a {Creator} {SourceType} that Zaal {captured} on {date}, {one-line why}. Not a meeting.

## The framework

**{FRAMEWORK NAME}** = {one-sentence pitch}.

| Component | Practice | Verbatim claim |
|---|---|---|
| **<label>** | **<name>** | "<verbatim quote>" Additional context. |
| ... | ... | ... |

## Why Zaal captured it

{1-3 sentences. Context from frames if video: visible browser tabs, what Zaal was working on, what triggered the capture.}

## What overlaps Zaal already does (memory cross-check)

Per `<relevant memory file>.md`: "{quote from memory}".

| {Framework component} | Already in Zaal's stack | Gap |
|---|---|---|
| <name> | <YES \| NO \| PARTIAL> - <how> | <what to refine, or "skip - does not apply", or "new lever"> |
| ... | ... | ... |

## Source

- [{Creator} - {Platform}](<source-url>) [FULL | PARTIAL - <what is missing> | FAILED - <what tried>]
- {local transcript path if applicable} [FULL - tool used, line count]
- {frames dir path if applicable} [FULL - frame count, what they show]
- Recording: `<path>` ({filesize}, ~{duration})

## Next Actions

| Action | Owner | Type | By When |
|---|---|---|---|
| <action that maps a gap into a real change> | @Zaal | Personal | <when> |
| ... | @Zaal | ... | ... |
```

---

## Required fields

- `framework_or_claim.name` MUST appear in the title.
- Frontmatter `original-query`, `last-validated`, `captured-from` are MANDATORY (per /zao-research v2 + skill conventions).
- "The framework" table MUST have verbatim quotes per component (no paraphrase).
- "Maps to Zaal stack" MUST cite at least one memory file or research doc - otherwise this is just a transcript dump.
- Source section MUST follow FULL / PARTIAL / FAILED classification per /zao-research Hard Req #11.

## Optional fields

- "Why Zaal captured it" - skip if context is in the original-query already.
- `memory_candidates` - usually empty; only add if a genuinely new pattern emerged.

## Anti-pattern

Do NOT write a "decisions" section. There are no decisions in content-capture - the creator made claims, Zaal hasn't decided anything yet. The Next Actions table is where Zaal's response lives.
