---
name: handoff
description: Compress the current Claude Code session into a portable markdown bundle the receiver can paste into a different session (same mac, different machine, claude.ai, future-you) and resume with zero context loss. Default voice - the receiver is already mid-work; the bundle leads with tasks to absorb into their existing todo list, decisions/git/in-flight/cold-start map are opt-in below. Lands as research/events/session-YYYY-MM-DD-<slug>/README.md in ZAO repos, ~/.zao/handoff/<slug>/ elsewhere. Pushes summary to Bonfire (best-effort). Auto-clipboards the bundle. Use when the user types /handoff, says "save my context", "summarize this session", "hand this off to another terminal", "move this work elsewhere".
allowed-tools: Read Write Edit Bash Skill
---

# /handoff - session handoff bundle

Compress this Claude Code session into a single paste-anywhere markdown bundle. Receiver pastes it into a new session and resumes.

Design doc: `research/dev-workflows/755-handoff-skill-design/README.md` (in ZAO repos).

## When to fire

- User types `/handoff`
- "save my context", "summarize this session", "hand off to another terminal"
- "move this work to my other laptop", "I want to pick this up later"
- About to /clear or /compact and want a portable artifact first
- Switching to claude.ai or a different agent and need to carry context

## The 5-section bundle (this is the output shape - do not deviate)

The bundle is **recursive-friendly**: the receiver pastes the whole thing into a fresh session and the model knows exactly what to do because of the receiver preamble at the top. The receiver can ALSO `/handoff` again later, chaining bundles. Each bundle's "Previous handoffs in chain" pointer keeps the lineage traceable.

```markdown
# Session handoff - YYYY-MM-DD HH:MM
> from <source machine + branch> -> to <receiver, default "fresh CC terminal">
> doc: <path-to-this-bundle>
> chain: <previous-handoff-path-or-none>

## Receiver instructions (read me FIRST, then do exactly this)

You just received a handoff bundle. Do NOT start work yet. Do this:

1. Read ALL sections below (A through E) before responding to anything.
2. If section C has a diff, decide: apply it (`git apply diff.patch`) or note it for later.
3. Create TaskList entries from section A. These are the "to do" items.
4. Use section B as your "why" - do NOT re-litigate decisions captured there unless new info surfaces.
5. Use section D to know what's still running (background jobs, wakeups, subagents).
6. Use section E as your cold-start map for files, skills, memory state.
7. Once integrated, message back: "Ingested handoff <slug>. <N> tasks queued. Ready."
8. If you /handoff later, your new bundle's `chain:` field points BACK to this bundle's path so the chain is traceable.

## A. Tasks to absorb (paste these into your TODO list)
- [ ] <task 1> - <one-line context>
- [ ] <task 2> - <one-line context>
- [ ] <task 3> - <one-line context>

## B. Why - decisions + pivots + ruled-out paths
- <decision 1> because <reason>. Ruled out <alternative> because <reason>.
- <decision 2> ...

## C. Git state
- Branch: `<branch>` (ahead N, behind M, dirty K files)
- Push status: `<pushed | unpushed | merged>`
- Uncommitted diff (apply with `git apply` from repo root):
  ```diff
  <unified diff>
  ```
- Untracked files: `<list>`

## D. In-flight
- Background bash jobs: <task_id - description - status>
- Subagents pending: <agent_type - task>
- Scheduled wakeups: <delaySeconds - reason>
- Open AskUserQuestion: <yes/no>

## E. Cold-start map (read if you are confused)
- Files touched this session: <relative paths + brief note>
- Skills invoked: `<skill_name>` - <count> - <last result>
- Memory writes: `<memory_slug>` - <new | updated> - <one-line>
- Last-known mental model: <2-3 sentences>
- Open questions for the receiver: <items to clarify with the user>
```

Section order is fixed: A is task-first because most receivers are mid-work and want the actionable item, not the backstory. B-E are opt-in.

## Phase 0 - Detect repo type

Run:
```bash
bash ${CLAUDE_SKILL_DIR}/scripts/handoff-detect.sh
```

It prints one of:
- `zao` - cwd has `research/events/` and `community.config.ts` -> ZAO OS V1 repo
- `bcz` - cwd matches BCZ repos pattern
- `other-repo` - inside a git repo but not ZAO -> output goes to `<repo-root>/.handoffs/session-<slug>/`
- `no-repo` - not in a git repo -> output goes to `~/.zao/handoff/<slug>/`

Output path rule:
- `zao` -> `research/events/session-YYYY-MM-DD-<slug>/`
- `bcz` -> `<repo-root>/.handoffs/session-<slug>/` (or wherever the project keeps similar artifacts)
- `other-repo` or `no-repo` -> `~/.zao/handoff/session-<slug>/`

## Phase 1 - Gather state (mechanical, runs scripts)

### 1a. Git state
```bash
bash ${CLAUDE_SKILL_DIR}/scripts/handoff-build.sh git
```
Outputs to `/tmp/handoff-git-<pid>.txt` - branch, push status, dirty file count, unified diff (capped at 500 lines; full diff goes to a sidecar `diff.patch` if larger).

### 1b. Files touched + skills invoked + memory writes
You (the model) collect these from conversation memory. The harness does not expose a tool-call audit log, so you derive them from what you actually did this session.

Format:
- Files touched: every path you Wrote or Edited. Group by directory if many.
- Skills invoked: every `Skill` tool call by name + a one-line result note.
- Memory writes: paths under `~/.claude/projects/.../memory/` you created or edited.

### 1c. In-flight state
- Background bash jobs: review your conversation - any `run_in_background: true` Bash calls that have NOT been marked complete in a system-reminder.
- TaskList: include any tasks with status `pending` or `in_progress` (use TaskList tool if available, else recall from conversation).
- ScheduleWakeup: any pending wakeups + their fire-time + reason.
- Open AskUserQuestion: did you ask a question that has no answer yet?

## Phase 2 - Synthesize sections A + B + E (you the model write these)

These three sections are the high-value parts. Mechanical gathering can't write them - the model has to reflect on the conversation.

### Section A - Tasks to absorb (3-5 bullets, the receiver's next moves)

Sources:
- Open TaskList items (pending + in_progress)
- ScheduleWakeup prompts (literal "do this later" content)
- "TODO" / "next step" Zaal said explicitly
- Background bash jobs that haven't completed cleanly
- PRs / commits / pushes the conversation flagged but didn't execute

Voice: imperative, one-line, with a colon-prefix indicating effort if known. Examples:
- `[ ] Re-fire bonfire for the 7 May 19-23 meetings (5 min, run bash ~/.claude/skills/meeting/scripts/bonfire-episode.sh /tmp/meeting-bonfire-episodes.json)`
- `[ ] Write recap doc 754 (~30 min, transcript already at /tmp/meeting-<id>.txt)`
- `[ ] Decide PR strategy for doc 754 - same branch as M8 or its own?`

3-5 items. If more, pick the most-blocking ones. If fewer than 3 real items, that's fine - don't pad.

### Section B - Why (decisions, pivots, ruled-out paths)

This is the expensive-to-reconstruct part. Source: your conversation memory. Pull:
- Explicit decisions ("we picked X because Y")
- Pivots ("tried Z first, abandoned because W")
- Ruled-out alternatives ("considered Q but skipped because R")
- Surprising findings the receiver shouldn't have to re-discover

Voice: declarative, past-tense, named-with-reason. Example:
- "Picked single-file markdown bundle (not multi-file split) because the receiver shouldn't need to know which file to grab first - friction kills the use case."
- "Decided NOT to wrap everything-claude-code:save-session - it's generic, ZAO needs Bonfire push + cowork tracker hooks that don't fit a wrapper."

5-10 items typical. Skip the obvious; capture the non-obvious.

### Section E - Cold-start map

| Sub-field | How to fill |
|-----------|-------------|
| Files touched | List from Phase 1b. Group by topic if many. |
| Skills invoked | List from Phase 1b. |
| Memory writes | List from Phase 1b. |
| Last-known mental model | 2-3 sentences. "We are mid-X. Just finished Y. Next step is Z." |
| Open questions | Items the receiver should clarify with the user before resuming. Empty is fine. |

## Phase 3 - Confirm with the user

Show the user the draft section A + B inline (NOT the whole bundle - too long). Ask:

> Section A draft (the tasks the receiver will absorb):
> - [ ] ...
> - [ ] ...
> Section B headline (the decisions you'll explain):
> - ...
>
> Receiver context (where is this going?):
> - [x] Another CC session on this mac (default)
> - [ ] CC on a different machine
> - [ ] claude.ai or a different agent
> - [ ] Future-you, weeks later
>
> Slug for the doc folder (default: `<auto-picked from section A>`): _______
> Targets to fire:
> - [x] Write the bundle doc
> - [x] Auto-clipboard for paste
> - [x] Bonfire push (default-on, best-effort)
> - [ ] Cowork tracker rows for section A tasks (opt-in)

Wait for confirmation. Edit Section A based on feedback before writing.

## Phase 4 - Write the bundle

Write the bundle to the path Phase 0 picked. Use the 5-section template verbatim (the structure in the "The 5-section bundle" section above).

If the unified diff is over 500 lines:
- Write a one-line-per-file summary inline in Section C
- Write the full diff to `<path>/diff.patch` as a sidecar
- Note in Section C: "Full diff at diff.patch (apply with `git apply diff.patch`)"

Sidecar files (only when relevant):
- `diff.patch` - if uncommitted diff is large
- `inflight.json` - if background jobs are running (raw state for debugging)
- `transcript.md` - if this session was processing a meeting (link to the source)

## Phase 5 - Secret + PII scan

Before writing, scan the bundle markdown for secrets + PII. Use the regex set from `.claude/rules/secret-hygiene.md` (project-local if available, else the patterns inlined below):

Secret patterns (HIGH severity):
- `sk-ant-[A-Za-z0-9_-]{20,}` (Anthropic key)
- `ghp_[A-Za-z0-9]{36}` (GitHub PAT)
- `sk-(proj-|cp-)?[A-Za-z0-9_-]{30,}` (OpenAI key)
- `-----BEGIN ([A-Z]+ )?PRIVATE KEY-----` (PEM)
- `0x[0-9a-fA-F]{64}` (private key / hash)
- `[0-9]{9,12}:[A-Za-z0-9_-]{30,}` (Telegram bot token)
- `AKIA[0-9A-Z]{16}` (AWS key)

PII patterns (per `.claude/rules/pii-hygiene.md`, in ZAO repos):
- third-party emails outside the public ZAO allowlist
- US phone numbers
- street addresses
- third-party Telegram handles

If any HIT, abort the write. Print to chat: `[handoff] ABORT - secret/PII match: <pattern>. Redact + re-run.` Do NOT auto-redact - that risks leaving partial leaks.

## Phase 6 - Bonfire (default-on, best-effort)

Build `/tmp/handoff-bonfire-episodes.json`:

```json
{
  "episodes": [
    {"name": "session:<date>:summary", "body": "<one paragraph: what was worked on, key decisions, where it ended>", "source_tag": "handoff:<slug>"},
    {"name": "session:<date>:task-1", "body": "From the <date> session, <action title>. Context: <one-line>.", "source_tag": "handoff:<slug>"}
  ]
}
```

One summary episode + one per section-A task. Run:
```bash
bash ~/.claude/skills/meeting/scripts/bonfire-episode.sh /tmp/handoff-bonfire-episodes.json
```

The `bonfire-episode.sh` script handles all env loading + secret-scanning + best-effort posting (post doc 754, it reads `~/.zao/zao.env` correctly). If env is missing it prints "skipped (no key)" and exits 0.

## Phase 7 - Auto-clipboard

Hand the bundle markdown off to the `/clipboard` skill so Zaal can paste in one Cmd+V:

```
/clipboard <path-to-bundle-README.md>
```

`/clipboard` opens a local browser page with the markdown ready-to-copy + saves to `~/.zao/clipboard/` for browsing.

## Phase 8 - Report

```
[OK] Bundle -> research/events/session-YYYY-MM-DD-<slug>/README.md
[OK] Diff -> diff.patch sidecar (NN lines)
[--] Bonfire - skipped (no key)  |  [OK] Bonfire - N episodes posted
[OK] Clipboard - ready to paste from ~/.zao/clipboard/session-<slug>.html
[OK] Or copy-paste this whole block into a fresh CC terminal:

<bundle markdown inline>
```

End with the actual bundle inline (last) so the user can long-press-copy it directly from the terminal if they don't want to open the clipboard page.

## Hard rules

- **Default voice: receiver is mid-work.** Section A is "tasks to absorb into your TODO list", not "things you need to know." Tone is "add these to your list" not "here's the situation."
- **Never include the full conversation transcript** in the bundle. Section B's job is to compress it. Section E's "mental model" is 2-3 sentences max.
- **Never auto-write decisions without confirming Section A with the user first.** Skip this only on `--auto` flag (for chained workflows).
- **Never push to remote git** as part of `/handoff`. The bundle includes the diff for portability; the user pushes themselves if they want.
- **Never commit the bundle to git.** Write to disk, but commit is the user's call. Bundles are draft artifacts.
- **No emojis. No em dashes.** Use hyphens. Per global feedback rules.

## Anti-patterns

- Do NOT wrap `everything-claude-code:save-session`. Native build per doc 755 decision #6.
- Do NOT write the bundle as multiple files for "easier reading" - the spec is single-file. Sidecars are only for the diff + inflight raw state, not for splitting the bundle itself.
- Do NOT post the FULL conversation to Bonfire. Only summary + section-A tasks.
- Do NOT include section-A items the user pushed back on - if they edited the draft, write what they confirmed.

## Receiver flow (for documentation; not part of this skill)

Receiver gets the bundle. Two paste flows:
1. **Same-mac fast path**: open a new CC terminal, type `/handoff-resume <path-to-bundle-README>` (v2 skill, not yet shipped).
2. **Manual path (v1)**: open any chat surface, paste the bundle. The receiving model reads it, integrates section A into TaskList, and reads B-E as it works.

## Scripts

- `scripts/handoff-detect.sh` - print repo type (zao/bcz/other-repo/no-repo) + suggested output path
- `scripts/handoff-build.sh git` - emit git state + diff to a tmp file
- (v2) `scripts/handoff-bonfire.sh` - thin wrapper that builds the episodes JSON + calls bonfire-episode.sh

## References

- `references/bundle-template.md` - the exact 5-section markdown template (copy-paste-able)
- Doc 755 (in ZAO OS V1) - design spec
- Doc 754 (in ZAO OS V1) - Bonfire push unblock that makes Phase 6 work
- Doc 717 (in ZAO OS V1) - upstream architecture context
