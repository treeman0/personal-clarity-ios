# ClarityHub V1 Acceptance Record

This record is the manual execution artifact for `docs/V1_ACCEPTANCE_RUNBOOK.md`. It is intentionally not marked accepted until each pass/fail field is filled with real iPhone or simulator evidence.

Generate a current release-candidate copy with `.\scripts\new-v1-acceptance-record.ps1 -OutputPath docs\V1_ACCEPTANCE_RECORD.md` immediately before starting manual acceptance.

## Release Candidate

```text
Candidate commit: run .\scripts\v1-local-status.ps1 and copy Local HEAD
Date:
Tester:
Device or simulator:
iOS version:
Apple ID / iCloud state:
HealthKit data state:
Google OAuth client ID available: yes/no
Cal AI writes nutrition to Apple Health: yes/no/unknown
```

## Automated Evidence

```text
Source command: .\scripts\v1-local-status.ps1
Copy from section: Acceptance record auto-fill
Local/remote status:
Loop status:
Release verifier:
Latest GitHub Actions runs:
iOS CI:
CodeQL:
Result bundle artifact:
Repository visibility:
GitHub security features:
Open security alerts:
Additional automated coverage:
```

## Clean Install Pass

```text
Light mode empty states pass/fail:
Dark mode empty states pass/fail:
Notes:
Screenshots captured:
```

## Core Data Entry Pass

```text
Goals pass/fail:
Habits pass/fail:
Lists/projects/tasks pass/fail:
Review pass/fail:
Nutrition pass/fail:
Notes:
Screenshots captured:
```

## Today Operating Pass

```text
Today pass/fail:
Dense data pass/fail:
Long text pass/fail:
Notes:
Screenshots captured:
```

## Integration Pass

```text
HealthKit pass/fail:
Notifications pass/fail:
Google Calendar pass/fail:
Nutrition integration pass/fail:
Notes:
Screenshots captured:
```

## Persistence And Sync Pass

```text
Relaunch persistence pass/fail:
Private CloudKit sync pass/fail/not available:
Notes:
Screenshots captured:
```

## Defect Log

| ID | Area | Severity | Finding | Evidence | V1 decision |
| --- | --- | --- | --- | --- | --- |
| A-001 |  |  |  |  | fix/defer |

## Acceptance Decision

```text
Accepted for V1: no
Reason: Manual iPhone/simulator acceptance has not been executed yet.
Reviewer:
Date:
```
