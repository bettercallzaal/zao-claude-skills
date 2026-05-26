---
name: ask-gpt
description: Send a prompt to the user's ChatGPT (GPT-5 via codex CLI, ChatGPT-account auth, no API costs). Use when you want a second opinion from GPT, want to cross-validate research, want to pull context GPT might know that you don't, or run a multi-turn learning loop where Claude and GPT iterate on a topic. Logs all Q+A to ~/.zao/gpt-loop/<topic>.log so context persists across sessions.
allowed-tools: Bash, Read, Write
argument-hint: "<topic-slug> <prompt> | <topic-slug> --resume <prompt> | <topic-slug> --show"
---

# /ask-gpt — Prompt user's ChatGPT, log Q+A, run learning loops

Wraps `~/bin/zao-ask-gpt.sh` which uses the `codex` CLI authenticated via Zaal's ChatGPT account (no API key billing).

## When to invoke

- "Ask GPT what they think of <X>"
- "Get a second opinion from ChatGPT on <X>"
- "Loop with GPT on <X>" (multi-turn conversation)
- During `/zao-research`: cross-validate findings with GPT
- During `/plan-eng-review` or `/plan-ceo-review`: get a third voice
- When Claude is uncertain: ask GPT, see if responses converge

## When NOT to invoke

- For information that's already in ZAO research or memory (use `/zao-research` first)
- For code generation (use Claude directly; codex skill if specifically Codex-style work)
- For chat purely about ZAO context (Claude has the memory; GPT does not unless we feed it)

## Three modes

### Mode 1 — One-shot question

```bash
~/bin/zao-ask-gpt.sh <topic-slug> "<prompt>"
```

Fresh log per topic. GPT has no prior context unless you include it in the prompt.

### Mode 2 — Resume / multi-turn loop

```bash
~/bin/zao-ask-gpt.sh <topic-slug> --resume "<follow-up>"
```

Reads last ~200 lines of the topic log, prepends as context, sends new question. Use this for the **learning loop** pattern.

### Mode 3 — Show log

```bash
~/bin/zao-ask-gpt.sh <topic-slug> --show
```

Prints all Q+A for that topic. Use this before deciding what to ask next.

## The Learning Loop Pattern

For any non-trivial research / decision, run this 3-pass minimum:

```
Pass 1 (kick off):
  /ask-gpt <slug> "Here's the question: <X>. What's your initial take?"

Pass 2 (challenge):
  Read GPT's answer. Find the weakest claim or biggest gap.
  /ask-gpt <slug> --resume "On point Y, you assumed Z. Is that true given <data>?"

Pass 3 (synthesize):
  /ask-gpt <slug> --resume "Given the above, what would you do if you were
  building this for ZAO (188-member Farcaster music community on Base)?"
```

After each pass, Claude reads the answer + ZAO memory + research docs and decides:
- Accept GPT's claim (record in research doc)
- Push back (next loop turn)
- Stop (have enough)

The log file is the **shared context**. Future Claude sessions read it via `--show` to pick up where the last session left off.

## ZAO-Specific Topic Slugs (Suggested)

| Slug | Use for |
|---|---|
| `zaostock-pitch` | Sponsor outreach copy, 1-pager critique, ticket-tier pricing |
| `zao-music-strategy` | Cipher release plan, distribution choices |
| `wavewarz-design` | Prediction market mechanics, artist signal scoring |
| `zoe-architecture` | Brand-bot fleet, knowledge-layer structure |
| `agent-stack` | QuadWork vs 1code vs DevFleet decisions |
| `dev-research-<topic>` | One-off research questions |

Use kebab-case. One slug per ongoing thread. Don't reuse slugs for unrelated topics — context will mix.

## Including ZAO Context in the Prompt

GPT does NOT have ZAO memory. For any ZAO-specific question, include the relevant context inline:

```
/ask-gpt zaostock-pitch "Context: ZAO is a 188-member Farcaster music community
on Base. ZAOstock is our Oct 3 2026 festival in Ellsworth ME at Franklin St
Parklet. Budget $5-25K. We need sponsor pitch tiers ($500/$1500/$5000/$10000+).

Question: What's the strongest single sentence to open a cold email to a local
brewery about Bronze-tier sponsorship?"
```

After Pass 1, the log has this context — subsequent `--resume` calls auto-include it.

## Cost

Free per query because codex uses Zaal's ChatGPT Plus/Pro auth (not API key). Watch usage on `chatgpt.com` if approaching plan limits.

## Failure Modes

| Symptom | Recovery |
|---|---|
| `codex login status` returns "Not logged in" | Run `codex login` once; opens browser, sign in |
| Empty answer | Check `~/.codex/log` for codex errors; retry |
| GPT response cut off | Increase context budget; ask "continue" via `--resume` |
| Context drift across topics | Use stricter slug naming; one slug per thread |

## Memory + Cross-Refs

After a productive loop, save a memory:

```
project_gpt_loop_<slug>.md
type: project
description: GPT loop on <slug> resolved <key finding>; full thread at ~/.zao/gpt-loop/<slug>.log
```

So future Claude sessions know the loop happened + can resume without re-reading the full log.

## Cross-References

- `~/bin/zao-ask-gpt.sh` — implementation
- `codex` skill — direct codex CLI access (deeper / interactive)
- `everything-claude-code:agent-eval` — head-to-head agent comparison (uses similar pattern)
- Doc 555 — Agent harness shootout (1code vs QuadWork vs ECC)
- Memory `feedback_prefer_claude_max_subscription` — same philosophy: use ChatGPT account auth, not API billing
