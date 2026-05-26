---
skill: handoff
date: 2026-05-26
slug: first-two-fires
average: 4.75
session-context: First two real /handoff fires happened in parallel sessions on 2026-05-25/26 - clay-research-and-capture-skill-spawn (Zaal's other terminal) and livekit-pion-research-and-leeward-call (third terminal). Both shipped the day the skill was built.
---

# Eval - handoff - 2026-05-26 - first-two-fires

## Run context

Two real /handoff invocations happened the same day the skill shipped. Bundle 1 captured a session that spawned the /capture skill (PRs #695 + #697 + #698, doc 753 + 756). Bundle 2 captured the full Pion/LiveKit research arc (PRs #688 + #693 + #696, docs 741 + 741a-d + 752). Zaal pasted both back into a fourth session and asked "lets see how it worked." This eval grades both as a paired comparison since they are sibling fires of the same fresh skill.

## Scores

### Bundle 1 (clay-research-and-capture-skill-spawn)

| Dimension | Score | Evidence |
|-----------|-------|----------|
| Trigger fit        | 5/5 | Session was the /capture skill spawn arc end-to-end; /handoff fired at the right moment |
| Output shape       | 4/5 | All 5 sections present + creative addition: "Inline copy-paste block" at bottom (not in spec but strictly better) |
| Completeness       | 5/5 | All phases ran; included sidecar paths + tracker-row inventory |
| Accuracy           | 5/5 | Cited specific commit shas (97a54be3, d0e2ba62), branch names, friction-source called out |
| Confidence honesty | 5/5 | Explicit about sandbox blocks ("git reset --hard sandbox block was the dominant friction-source") + left as manual follow-up |
| User satisfaction  | 4/5 | No pushback when paste-shared back; neutral-positive signal (Zaal said "seems like handoff works") |
| **Average**        | **4.67/5** | |

### Bundle 2 (livekit-pion-research-and-leeward-call)

| Dimension | Score | Evidence |
|-----------|-------|----------|
| Trigger fit        | 5/5 | Pion/LiveKit research arc spanning 3 PRs - exactly the multi-PR session /handoff is built for |
| Output shape       | 5/5 | Clean spec adherence, chain field present, structured E section with sub-sections (Files / Skills / External writes / Mental model / Open questions) |
| Completeness       | 5/5 | All 5 sections + open questions specifically for the receiver |
| Accuracy           | 5/5 | Precise (Airtable recnums recjcB42SSH7ObMqm + reclucHPCfMVu6C03, ssh zaal@31.97.148.88, exact cron paths, exact PR numbers) |
| Confidence honesty | 5/5 | Flagged bonfire-episode.sh env-loading bug + accidental stale-episode re-fire + cross-wired parallel-session branch |
| User satisfaction  | 4/5 | Same: no pushback, paste-shared back as evidence the skill works |
| **Average**        | **4.83/5** | |

## Combined average

**4.75/5 across both bundles** on first real fire. Skill spec is sound.

## Recommendations

1. **Add "Inline copy-paste block" to the official template** - Bundle 1 invented this and it's strictly better than the receiver having to scroll. Applied to SKILL.md + bundle-template.md.

2. **Formalize `chain:` field semantics** - Bundle 1 used informal prose ("chain: none for this branch; sibling parallel-session bundle at..."). Spec now defines three shapes: `none`, `<path>`, `sibling:<path>`. Applied.

3. **Skip startup-hook overlays in "Skills invoked"** - Bundle 1 listed `caveman:caveman - 1 - active throughout session per startup hook`. That's a session-wide overlay, not a discrete invocation. Spec now says: "List discrete /skill calls only - skip startup-hook overlays." Applied.

4. **Promote "friction-source surfacing" to a hard rule** - Both bundles' highest-value content was the explicit calling-out of sandbox blocks, ENOSPC, env-loading bugs, and stale-cache issues. The SKILL.md should explicitly require this in Section B. Applied.

## Applied

- [x] Rec 1 - Inline copy-paste block - applied 2026-05-26 to SKILL.md + bundle-template.md
- [x] Rec 2 - chain field semantics - applied 2026-05-26 to SKILL.md + bundle-template.md
- [x] Rec 3 - skip overlays - applied 2026-05-26 to bundle-template.md
- [x] Rec 4 - friction-source as hard rule - applied 2026-05-26 to SKILL.md

## Future eval triggers

- Next /handoff fire where receiver actually paste-ingests in a fresh CC session and tries to resume - score "User satisfaction" with their resume success, not just the bundle's own quality.
- Any /handoff that breaks because the cold-start map missed something - that's an output-shape OR completeness regression worth grading.
- Cross-machine /handoff (mac -> different machine) - the diff.patch sidecar logic has not been tested in production yet.
- /handoff -> /skill-eval -> /autoresearch full closed-loop run - first time we measure whether the autoresearch iteration actually improves the score.

## Notes

Both bundles are sibling fires - the lineage between them is "happened the same day, different sessions, both about ZAO work" rather than chained. The new `sibling:<path>` shape captures this correctly. Future work: when the chain crosses time-zones (e.g. ZAO Devz teammate's session in a different region), the bundle should still work - test when Iman or ThyRev fires their first /handoff.

Total skills the /handoff system depends on: /clipboard (for auto-paste), /bonfire (for KG episodes - works since doc 754 Patch 1 landed), bonfire-episode.sh, the PostToolUse auto-sync hook. The chain of dependencies held on both fires.
