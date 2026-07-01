---
name: auto-skill-review
description: Review automatic skill opportunity signals and propose new or updated skills. Use when repeated workflows appear, after loop retrospectives, or when .claude/state/skill-opportunities.json exists.
argument-hint: "<optional focus>"
context: fork
agent: skill-curator
---

# Auto Skill Review

Focus: $ARGUMENTS

1. Read `.claude/state/skill-opportunities.json` if it exists.
2. Inspect existing `.claude/skills/` names and descriptions.
3. Identify repeated workflows, commands, or decision procedures that would benefit from a skill.
4. Prefer updating an existing skill proposal over creating a duplicate.
5. Write proposed skills under `.claude/skills/_proposals/<skill-name>/SKILL.md`.
6. Do not promote a proposal into active skills unless the user explicitly approves it.
7. Update `wiki/` if the skill proposal captures durable project knowledge.

End with:

- proposed skills
- existing skills to update
- signals ignored and why
- validation needed before promotion

