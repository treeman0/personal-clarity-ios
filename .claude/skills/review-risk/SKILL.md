---
name: review-risk
description: Run a read-only risk review of the current change set with an independent reviewer subagent. Prefer Codex-backed review when available.
context: fork
agent: codex-reviewer
---

# Risk Review

Review the current change set for bugs, regressions, security issues, missing tests, and unsafe automation behavior.

Prefer the OpenAI Codex plugin for Claude Code:

```text
/codex:review --background
```

For design pressure-testing:

```text
/codex:adversarial-review --background <focus>
```

Return findings first, ordered by severity. Include exact files or commands when available. If there are no findings, say that clearly and name any test gaps.
