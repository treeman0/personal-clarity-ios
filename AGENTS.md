# Agent Instructions

These instructions are shared by Claude Code and Codex.

Before substantial work, read `.claude-loop.json` and follow the enabled loop parts. Older configs may keep some options at the top level; treat nested `loop.*` and `runtimes.*` settings as the preferred shape.

## Working Style

- Read the relevant files before changing code.
- Keep edits narrow and aligned with the existing project style.
- Prefer failing tests before implementation for behavior changes when `loop.tdd` is enabled.
- Separate maker and checker roles: the implementer does not certify its own work.
- Use a review pass when `loop.codeReview` is `required`, and when requested or risk is high if it is `manual`.
- Do not claim completion from intent, partial output, or visual plausibility.

## Runtime Surfaces

- Claude Code uses `CLAUDE.md`, `.claude/rules/`, `.claude/skills/`, `.claude/agents/`, and `.claude/hooks/`.
- Codex uses this `AGENTS.md`, `.agents/skills/`, `.codex/loop.md`, `.codex/config.toml`, and `.codex/hooks.json`.
- Both runtimes use `.claude-loop.json`, `wiki/`, and the scripts under `.claude/scripts/` when present.

## Customizable Loop Parts

- `loop.tdd`: prefer failing tests before implementation.
- `loop.verificationGate`: require a relevant verification command or explicit verification gap before completion.
- `loop.wikiMemory`: preserve durable project knowledge in `wiki/`.
- `loop.wikiGate`: require a wiki update or clear no-wiki rationale after meaningful changes.
- `loop.skillTracking`: notice repeated workflows and propose skills instead of silently accumulating ritual.
- `loop.codeReview`: `off`, `manual`, or `required`.
- `loop.safetyGuard`: keep destructive-command guardrails active in Claude and Codex hooks.
- `loop.statusReport`: use `.claude/scripts/status-report.ps1` for cockpit state when available.

## Definition of Done

- The requested behavior is implemented.
- Relevant tests or checks pass.
- Important assumptions and residual risks are reported.
- When `loop.wikiMemory` is enabled, durable knowledge that will matter later is added to `wiki/` through `wiki-ingest` or a focused wiki edit.
- When `loop.wikiGate` is enabled and no wiki update is warranted after changing files, explain why or write `.claude/state/wiki-review-waiver.md` when Claude hooks require it.
