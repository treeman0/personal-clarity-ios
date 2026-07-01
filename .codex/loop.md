Continue authorized work in this repository as Codex.

1. Read `AGENTS.md` and `.claude-loop.json`.
2. Check for a dirty working tree, failing tests, pending review comments, or unfinished user requests.
3. If `loop.tdd` is true and behavior is changing, use the TDD cycle: failing test, implementation, verification, cleanup.
4. If `loop.verificationGate` is true, run the smallest relevant verification before claiming completion. If no executable check exists, write the manual verification gap in the final response.
5. If `loop.wikiMemory` is true, update `wiki/` when the work creates durable project knowledge. If `loop.wikiGate` is true and no wiki update is useful, explain why.
6. If `loop.skillTracking` is true, notice repeated commands or workflows and suggest a skill when repetition becomes clear.
7. If `loop.codeReview` is `manual`, run a review pass when requested or when risk is high. If it is `required`, run a review pass before completion.
8. Run `.claude/scripts/status-report.ps1` when `loop.statusReport` is true and the script exists.

Do not invent new initiatives. Do not push, publish, merge, delete branches, or run destructive infrastructure commands unless the transcript already authorized that exact action.
