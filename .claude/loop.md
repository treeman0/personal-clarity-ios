Continue authorized work in this repository.

1. Read `.claude-loop.json`.
2. Check for unfinished tasks in the current conversation, failing tests, open review comments, or a dirty working tree.
3. If `loop.tdd` is true and behavior is changing, use the TDD cycle: failing test, minimal implementation, passing verification, refactor if useful.
4. If a subtask would produce noisy output, delegate it to a focused subagent and return only the result.
5. If all work is quiet, run a small maintenance pass: inspect one likely risk area, simplify only when the improvement is obvious, and verify.
6. If `loop.wikiMemory` is true, update `wiki/` when you discover reusable project knowledge.
7. If `loop.skillTracking` is true and `.claude/state/skill-opportunities.json` contains candidate workflows, run `auto-skill-review` and leave proposed skills under `.claude/skills/_proposals/`.

Do not invent new initiatives. Do not push, publish, merge, delete branches, or run destructive infrastructure commands unless the transcript already authorized that exact action.
