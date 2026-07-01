# Skill Automation

- Treat repeated workflows as skill candidates.
- The `track_skill_opportunities.ps1` hook records repeated shell commands in `.claude/state/skill-opportunities.json`.
- When candidates appear, use the `auto-skill-review` skill or `skill-curator` agent.
- New skills start as proposals under `.claude/skills/_proposals/`.
- Do not promote, overwrite, or delete active skills unless the user explicitly approves it.
- Prefer improving an existing skill over adding a near-duplicate.
- Keep skills concise; move detailed project knowledge to `wiki/` and deterministic helper logic to scripts only when needed.

