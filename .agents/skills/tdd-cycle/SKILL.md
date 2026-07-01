---
name: tdd-cycle
description: Use for Codex test-first implementation work when behavior changes, bugs need fixing, or a feature needs focused verification.
---

# TDD Cycle

Read `.claude-loop.json` before starting. If `loop.tdd` is false, use this skill only when explicitly requested.

1. Identify the smallest behavior change.
2. Add or update a failing test when practical.
3. Run the focused test and confirm the failure is meaningful.
4. Implement the smallest useful change.
5. Run the focused test again.
6. Broaden verification when the touched surface is shared, risky, or user-facing.
7. Refactor only after the behavior is passing.
8. Report what was verified and any remaining risk.

If the project has no suitable test harness, create a characterization check or explain the verification gap clearly.
