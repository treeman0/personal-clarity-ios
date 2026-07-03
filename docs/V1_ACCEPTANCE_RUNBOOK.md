# ClarityHub V1 Acceptance Runbook

Use this runbook to execute `docs/V1_ACCEPTANCE.md` for a release candidate, and record the result in `docs/V1_ACCEPTANCE_RECORD.md`. V1 is not complete until this runbook has been executed, the latest `main` CI run is green, loop status is clean, and every defect found here is fixed or explicitly deferred outside V1.

## Preflight

Before starting final manual acceptance, commit and push all intended release-candidate changes, wait for the current `origin/main` iOS CI and CodeQL runs to pass, and confirm `git status --short --branch -- . ':(exclude)docs/V1_ACCEPTANCE_RECORD.md'` shows only `## main...origin/main`. Then generate the acceptance record so its automated evidence points at the same candidate that will be tested manually. The acceptance record itself is allowed to be dirty while it is being filled.

Record this before starting:

```text
Candidate commit:
Date:
Tester:
Device or simulator:
iOS version:
Apple ID / iCloud state:
HealthKit data state:
Google OAuth client ID available: yes/no
Cal AI writes nutrition to Apple Health: yes/no/unknown
```

Use `docs/V1_ACCEPTANCE_RECORD.md` as the working evidence file for this release candidate. Do not mark `Accepted for V1` as `yes` until every pass/fail field is filled from a real iPhone or simulator run and all defect rows are fixed or explicitly deferred outside V1.

Required automated evidence:

```bash
swift test
bash scripts/verify-release-config.sh
xcodegen generate
xcodebuild test -project ClarityHub.xcodeproj -scheme ClarityHub -destination "platform=iOS Simulator,name=iPhone 16" CODE_SIGNING_ALLOWED=NO
```

If GitHub Actions cannot start because of billing, runner, or account limits, do not mark V1 complete. Record the failed run URL and rerun after the external issue is fixed.

On Windows, run this helper before handoff. It records local/remote Git state, loop gates, release verifier output, Swift availability, latest GitHub Actions runs, repository visibility/security settings, open security-alert counts, and the latest retained iOS `.xcresult` artifact:

```powershell
.\scripts\v1-local-status.ps1
```

To start a fresh manual acceptance artifact from the current release-candidate evidence, run the starter. It generates `docs/V1_ACCEPTANCE_RECORD.md`, runs the validator, and prints the remaining manual steps:

```powershell
.\scripts\start-v1-acceptance.ps1
```

If you only need to regenerate the record without the starter summary, run:

```powershell
.\scripts\new-v1-acceptance-record.ps1 -OutputPath docs\V1_ACCEPTANCE_RECORD.md
```

After filling the record, run the local validator before calling V1 accepted. It must pass before the goal can be marked complete:

```powershell
.\scripts\test-v1-acceptance-record.ps1
```

To see a shorter grouped list of remaining manual evidence gaps while filling the record, run:

```powershell
.\scripts\show-v1-acceptance-gaps.ps1
```

`Private CloudKit sync pass/fail/not available` may be marked `not available` while setup is still blocked, but the validator requires `pass` or `fail` before final V1 acceptance because private iCloud sync is in scope for V1.

## Clean Install Pass

Start from a clean app install or erased simulator content.

1. Launch the app.
2. Open every tab: Today, Body, Goals, Habits, Lists, Calendar, Nutrition, Review, Settings.
3. Confirm each empty state is useful and non-crashing.
4. In Today, confirm Setup appears and shows readiness for body target, reminder, Google Calendar, first goal, first habit, task capture, and nutrition path.
5. Switch iOS appearance to dark mode and repeat the tab pass.

Evidence:

```text
Light mode empty states pass/fail:
Dark mode empty states pass/fail:
Notes:
Screenshots captured:
```

## Core Data Entry Pass

Create dense but realistic data.

1. Settings: set goal weight and weigh-in reminder time.
2. Goals: create at least two measurable goals, including duplicate titles, one with a due date.
3. Goals: update a current value and add a linked next action.
4. Habits: create one daily habit and one custom weekday habit.
5. Habits: complete and uncomplete a due habit, then complete it again.
6. Lists: create a todo list, project-support list, reference list, and a project with a long desired outcome.
7. Lists: create tasks with priority, due date, list, project, and goal context.
8. Lists: complete a task, confirm it appears in Completed, restore it, complete it again, then delete it from Completed.
9. Review: save a daily review with next focus, edit the same-day review, and save a weekly review.
10. Nutrition: parse a manual or Cal AI-style import, change the date or source, and confirm the parsed result clears until it is parsed again.
11. Nutrition: save manual or Cal AI-style daily totals for today and at least two prior days.

Evidence:

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

Return to Today after the data entry pass.

1. Confirm weight state or empty state is clear.
2. Confirm latest review focus appears.
3. Confirm goal progress appears for each goal, including duplicate-titled goals.
4. Confirm habit count reflects due/completed habits.
5. Confirm priority tasks show due-date/list/project/goal context.
6. Confirm recent nutrition average appears.
7. Confirm calendar blocks show when connected, or a clear setup/disconnected message appears when not connected.
8. Confirm dense content remains scannable in light and dark mode.

Evidence:

```text
Today pass/fail:
Dense data pass/fail:
Long text pass/fail:
Notes:
Screenshots captured:
```

## Integration Pass

HealthKit:

1. Request body-weight permission from Body or Setup.
2. Test an account/device with no body-weight samples if available.
3. Request nutrition permission from Nutrition or Setup.
4. Confirm denied permissions produce clear non-crashing status messages.

Notifications:

1. Schedule the daily weigh-in reminder.
2. Trigger or wait for the daily reminder notification and confirm the Snooze 15 min action is available.
3. Use the notification Snooze 15 min action and confirm a snooze reminder is scheduled.
4. Snooze from Body.
5. Trigger or wait for the snoozed reminder notification and confirm the Skip snooze action is available.
6. Skip pending snooze from the notification action or Body.
7. Confirm no duplicate pending snooze remains.

Google Calendar:

1. Save OAuth client ID and redirect URI in Settings.
2. Connect from Calendar.
3. Refresh upcoming events.
4. Create a focus block.
5. Verify the block exists in Google Calendar.
6. Tap Disconnect in Calendar and confirm events clear with a reconnect message.
7. Change OAuth settings and confirm Calendar requires reconnect instead of silently reusing stale tokens.

Nutrition / Cal AI:

1. If Cal AI writes to Apple Health, confirm Apple Health nutrition import works.
2. Otherwise, confirm manual/Cal AI text import works and replaces same-day records cleanly.

Evidence:

```text
HealthKit pass/fail:
Notifications pass/fail:
Google Calendar pass/fail:
Nutrition integration pass/fail:
Notes:
Screenshots captured:
```

## Persistence And Sync Pass

1. Force-quit and relaunch the app.
2. Confirm all app-owned records persist: goals, habits, check-ins, lists, tasks, projects, nutrition days, reviews, preferences.
3. With release signing and iCloud available, install on two signed-in devices.
4. Create records on device A and confirm they sync to device B through private CloudKit.

Evidence:

```text
Relaunch persistence pass/fail:
Private CloudKit sync pass/fail/not available:
Notes:
Screenshots captured:
```

## Defect Log

Use this table for every issue found.

| ID | Area | Severity | Finding | Evidence | V1 decision |
| --- | --- | --- | --- | --- | --- |
| A-001 |  |  |  |  | fix/defer |

V1 can be accepted only when all rows are fixed or explicitly deferred outside V1.
