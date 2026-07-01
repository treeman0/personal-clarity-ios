# Codex Runtime

This folder contains Codex-facing runbooks for the Claude Loop System.

Codex automatically reads repository `AGENTS.md`. Use that file as the shared contract between Claude Code and Codex. Use this folder for Codex-specific operating notes, project config, and trusted-project hooks.

Default entry points:

- `.codex/loop.md` - the Codex maintenance loop
- `.codex/hooks.json` - Codex lifecycle hook configuration
- `.codex/hooks/` - Codex enforcement hooks for safety, verification, wiki review, and skill tracking
- `.agents/skills/tdd-cycle/SKILL.md` - test-first implementation workflow
- `.agents/skills/wiki-ingest/SKILL.md` - durable knowledge capture
- `.agents/skills/maintenance-report/SKILL.md` - cockpit/status check
- `.agents/skills/review-risk/SKILL.md` - independent review pass

Loop behavior is controlled by `.claude-loop.json`.

Codex project-local hooks only run after the project `.codex/` layer is trusted. Use `/hooks` in Codex to inspect and trust changed hooks.
