---
name: maintenance-report
description: Report Claude loop system maintenance state including pending verification, wiki review, skill candidates, preserved docs, migration indexes, and active gates.
argument-hint: "<optional target path>"
disable-model-invocation: true
---

# Maintenance Report

Run:

```powershell
.\.claude\scripts\status-report.ps1
```

If a target path is supplied:

```powershell
.\.claude\scripts\status-report.ps1 -TargetPath "<path>"
```

Use the report to decide what to do next:

- pending verification -> run tests or write a verification waiver
- pending wiki review -> update `wiki/` or write a wiki waiver
- skill candidates -> run `auto-skill-review`
- preserved docs -> inspect `wiki/inbox/replaced-by-install/`
- link suggestions -> inspect `wiki/sources/link-rewrite-suggestions.md`

