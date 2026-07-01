---
name: maintenance-report
description: Use when Codex should summarize loop status, pending verification, wiki review state, migration indexes, preserved docs, and active loop config.
---

# Maintenance Report

Run the repo status script when available:

```powershell
.\.claude\scripts\status-report.ps1
```

If the Claude runtime is disabled and the script is absent, inspect these manually:

- `.claude-loop.json`
- `wiki/sources/migrated-markdown-index.md`
- `wiki/sources/link-rewrite-suggestions.md`
- `wiki/sources/replaced-markdown-index.md`
- `.claude/state/needs-verification.json`
- `.claude/state/needs-wiki-review.json`
- `.claude/state/skill-opportunities.json`

Summarize only current maintenance actions, not every file in the scaffold.
