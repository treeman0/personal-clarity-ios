---
name: tdd-cycle
description: Run a test-driven implementation loop for a feature or bug. Use when the user asks to implement behavior safely or fix a regression.
argument-hint: "<feature-or-bug>"
context: fork
agent: general-purpose
---

# TDD Cycle

Goal: $ARGUMENTS

1. Use the `test-writer` subagent to add the smallest failing test for the requested behavior.
2. Confirm the test fails for the right reason.
3. Use the `implementer` subagent to make the smallest production change.
4. Run the focused test until it passes.
5. Use the `verifier` subagent to inspect the diff and run the relevant verification command.
6. Refactor only if it reduces real complexity and preserves passing tests.
7. Summarize the commands, results, and residual risks.

If no test harness exists, create the closest practical characterization test. If that is impossible, write `.claude/state/verification-waiver.md` with the reason and a manual verification checklist.

