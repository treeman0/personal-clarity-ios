---
name: loop-retrospective
description: Review recent agent loop behavior, token/cost risk, verification gaps, and memory updates.
argument-hint: "<optional scope>"
disable-model-invocation: true
---

# Loop Retrospective

Review the recent work for:

- repeated failures or loops without progress
- tests added after implementation instead of before it
- claims of completion without independent verification
- missing wiki updates for reusable knowledge
- commands that should become hooks
- procedures that should become skills
- repeated command candidates in `.claude/state/skill-opportunities.json`
- context bloat that should move to rules, wiki pages, or subagents

End with three actions: keep, change, remove.
