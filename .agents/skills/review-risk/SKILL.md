---
name: review-risk
description: Use for a Codex review pass over a diff, implementation plan, migration, security-sensitive change, data-loss risk, or verification gap.
---

# Review Risk

Read `.claude-loop.json`. If `loop.codeReview` is `off`, use this skill only when explicitly requested. If it is `required`, run this before completion for non-trivial changes.

Review in this order:

1. Correctness bugs and behavioral regressions.
2. Data loss, destructive actions, or migration hazards.
3. Security and secret-handling issues.
4. Missing or weak verification.
5. Maintainability concerns that are likely to matter soon.

Lead with findings. Use file and line references when available. If there are no findings, say that clearly and mention residual test gaps.
