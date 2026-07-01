---
name: codex-code-review
description: Run or coordinate OpenAI Codex as the independent code reviewer from Claude Code. Use before finalizing changes, before shipping, or when the user asks for a code review.
argument-hint: "<optional focus or base branch>"
context: fork
agent: codex-reviewer
---

# Codex Code Review

Review focus or base: $ARGUMENTS

Use the OpenAI Codex plugin for Claude Code when available.

## Normal Review

Ask the main Claude Code session to run:

```text
/codex:review --background
```

If a base branch is provided:

```text
/codex:review --base <base-branch> --background
```

Then check progress:

```text
/codex:status
/codex:result
```

## Adversarial Review

When the request involves architecture, data loss, auth, rollback, concurrency, caching, or reliability, ask for:

```text
/codex:adversarial-review --background <specific focus>
```

## Output

Return:

- Codex command used
- review status
- findings, ordered by severity
- fixes required before completion
- residual risk

If the plugin is not installed, say that and perform a read-only local review as fallback.

