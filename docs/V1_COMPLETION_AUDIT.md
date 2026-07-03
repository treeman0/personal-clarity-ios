# ClarityHub V1 Completion Audit

This audit maps the original V1 requirements to the evidence needed before the goal can be marked complete. Treat anything marked `Needs evidence` or `Blocked` as incomplete.

## Current Release Candidate

Update this block by running the commands below when performing a final V1 audit. Do not treat stale commit IDs in this file as evidence.

```text
Current local HEAD: run `git log -1 --oneline`
Current remote HEAD: run `git log -1 --oneline origin/main`
Current local/remote status: run `git status -sb`
Latest CI status: run `gh run list --repo treeman0/personal-clarity-ios --branch main --limit 3`
Current automated release-candidate evidence: run `.\scripts\v1-local-status.ps1` and use its `Acceptance record auto-fill` section as authoritative.
Last collected evidence before this audit update: do not use this file for current commit, CI, security, or artifact evidence; use `.\scripts\v1-local-status.ps1`.
Manual acceptance: not executed
Goal status: active, not complete
```

Known state as of 2026-07-03: the repository is public and GitHub Actions can start hosted macOS jobs without the previous private-repository billing block.
Use `.\scripts\v1-local-status.ps1` for current release-candidate status. It prints current local/remote HEADs, green or failing CI state, retained result artifact, security settings, and open security-alert counts for the current remote head.

On Windows, run `.\scripts\v1-local-status.ps1` to collect the local status, loop gate, release verifier, Swift availability, latest GitHub Actions summary, repository visibility/security settings, open security-alert counts, and latest retained iOS result bundle artifact in one pass.

## Workflow Requirements

| Requirement | Evidence | Status |
| --- | --- | --- |
| New repo named `personal-clarity-ios` | GitHub repo `treeman0/personal-clarity-ios` and local worktree | Achieved |
| `treeman0/claude-loop-system` installed with Codex flow | `AGENTS.md`, `.claude-loop.json`, `.agents/skills/`, `.codex/loop.md`, `.codex/config.toml`, `.codex/hooks.json`, `.codex/hooks/`, `wiki/`; loop status report | Achieved |
| Loop defaults enabled | `.claude/scripts/status-report.ps1` reports TDD, verification gate, wiki memory/gate, skill tracking, manual review, safety guard, status report enabled | Achieved |
| macOS CI runs Swift tests and Xcode builds on push/PR | `.github/workflows/ios-ci.yml`; latest pushed commit must have a green `iOS CI` run | Achieved by workflow; verify current HEAD with `.\scripts\v1-local-status.ps1` |
| Public-repo dependency update monitoring | `.github/dependabot.yml` monitors GitHub Actions and Swift package manifests; release verifier asserts the config remains present | Achieved, rerun after any new commit |
| Windows local development does not require Xcode | Local Windows gates run release verifier and loop status; macOS CI is authoritative for Swift/Xcode | Achieved with caveat |

## Product Requirements

| Area | Requirement | Evidence | Status |
| --- | --- | --- | --- |
| App shell | Native SwiftUI iPhone app with Today, Body, Goals, Habits, Lists, Calendar, Nutrition, Review, Settings | `RootTabView.swift`, generated Xcode CI build, `ClarityHubUITests` light/dark tab smoke | Achieved, needs full manual UI pass |
| Setup | Today setup checklist for defaults, core permissions, reminder scheduling, and denied notification feedback | `SetupChecklistView.swift`, reminder tests | Needs manual UI pass |
| Persistence | SwiftData with private CloudKit for app-owned data | `ClarityHubModelContainerFactory.swift`, entitlements, release verifier, disk-backed persistence recreation test, latest green CI | Needs signed-device sync smoke |
| Body | HealthKit body weight, goal comparison, trend chart, moving average, unique-day weigh-in streak | `HealthKitWeightStore.swift`, `BodyView.swift`, weight tests, sample-data UI smoke | Needs device/manual HealthKit pass |
| Reminders | Morning weigh-in reminders with configurable time, permission-denied handling, notification Snooze 15 min and Skip snooze actions, in-app snooze, and in-app skip | `WeighInReminderScheduler.swift`, `WeighInReminderNotificationActions.swift`, tests, Body/Settings UI | Needs device/manual notification delivery pass |
| Goals | Measurable goals, increase/decrease/maintain progress, optional due dates, current-value update, linked next actions, linked-task cleanup on delete | `GoalsView.swift`, goal progress and persistence tests | Needs manual UI pass |
| Habits | Daily/custom weekday habits, completion, cadence-aware streaks, delete with check-ins | `HabitsView.swift`, `HabitScheduleTests.swift`, persistence tests | Needs manual UI pass |
| Lists/projects | Todo/project/reference lists, project outcomes, priority/due/list/project/goal task capture, completed-task review, restore, and cleanup | `ListsView.swift`, task planner tests, list-kind persistence test, dense fixture list-kind UI smoke | Needs manual UI pass |
| Calendar | Google OAuth PKCE/consent, official Calendar API read/write, upcoming-window reads, direct disconnect, clear states | `CalendarView.swift`, `GoogleOAuthClient.swift`, `GoogleCalendarClient.swift`, tests | Needs real Google OAuth manual pass |
| Nutrition | Apple Health nutrition totals or Cal AI/manual import, comma-formatted and value-before-label import parsing, stale import clearing, history, averages, same-day replace/delete | `NutritionHealthStore.swift`, `NutritionView.swift`, parser/summary, persistence tests, sample Apple Health nutrition UI smoke | Needs device/manual nutrition pass |
| Today | Operating screen integrates setup, weight, focus, goals, habits, tasks, calendar, nutrition | `TodayDashboardView.swift`, latest green CI, dense-data and HealthKit sample `ClarityHubUITests` fixtures | Needs manual dense-data pass |
| Review | Daily/weekly reviews, same-day and same-week edit, deduplicated next-focus task creation | `ReviewView.swift`, review planner and persistence tests | Needs manual UI pass |
| Settings | Goal weight, reminder time, Google OAuth settings, reminder scheduling with denied-permission feedback | `SettingsView.swift`, preference and reminder tests | Needs manual UI pass |

## Integration Policy

| Requirement | Evidence | Status |
| --- | --- | --- |
| App Store-compatible public integrations only | Product spec, HealthKit/Google API implementation, no Cal AI scraping code | Achieved |
| Cal AI through Apple Health or user import only | `NutritionHealthStore.swift`, `NutritionImportParser.swift`, `NutritionView.swift` | Achieved, needs manual pass |
| Google tokens in Keychain, not CloudKit preferences | `KeychainTokenStore.swift`, `GoogleCalendarSession.swift`, product spec | Achieved |
| Read-only HealthKit metadata matches implementation | `Info.plist`, release verifier, release metadata tests, latest green CI | Achieved, rerun status before final acceptance |

## Automated Verification

| Gate | Current state | Status |
| --- | --- | --- |
| `git diff --check` | Passes on the current Windows worktree | Rerun after any new commit |
| `bash scripts/verify-release-config.sh` | Passes on the current Windows worktree | Passed locally; now also guards against deprecated checkout/CodeQL Action refs, missing Dependabot config, and missing CI timeouts |
| `.claude/scripts/status-report.ps1` | Passes with all loop defaults enabled | Rerun after any new commit |
| `.\scripts\v1-local-status.ps1` | Reports local/remote state, loop status, release verifier, Swift availability, latest Actions runs, repository visibility/security settings, open security-alert counts, latest retained iOS result bundle artifact, and acceptance-record auto-fill text | Run for the current release candidate |
| `.\scripts\start-v1-acceptance.ps1` | Generates the release-candidate acceptance record, runs the validator, and prints the remaining manual acceptance steps | Use to start manual acceptance |
| `.\scripts\show-v1-acceptance-gaps.ps1` | Prints a grouped summary of unfilled manual acceptance fields and evidence gaps while the record is being completed | Use during manual acceptance |
| `.\scripts\test-v1-acceptance-record.ps1` | Fails until the acceptance record has current automated evidence, all manual pass/fail fields filled, all screenshots/notes recorded, defects fixed or deferred outside V1, and `Accepted for V1: yes` | Run after manual acceptance |
| `.\scripts\test-v1-acceptance-tooling.ps1` | Fast smoke for the acceptance generator and validator: valid synthetic records pass, invalid preflight choices fail, missing screenshot evidence fails, mismatched candidate evidence fails, and generated blank records stay incomplete | Run after editing acceptance tooling |
| `swift test` | Not available on Windows host | Needs macOS |
| `xcodegen generate` | Not available on Windows host | Needs macOS |
| `xcodebuild test ...` | Not available on Windows host | Needs macOS |
| Latest `main` CI green | Run `.\scripts\v1-local-status.ps1` and confirm the iOS CI run for `origin/main` succeeded | Run for the current release candidate |
| Light/dark app-shell and setup-section smoke | `ClarityHubUITests.testV1SurfacesRenderInLightAndDarkMode` runs in the app scheme on macOS CI | Covered by latest green iOS CI for current HEAD |
| Dense fixture smoke | `ClarityHubUITests.testDenseTodayDataRendersInLightAndDarkMode` and `testDenseFixtureRecordsRenderAcrossPrimaryAreas` launch an in-memory fixture with goals, habits, long tasks, lists/projects, nutrition, preferences, and review focus | Covered by latest green iOS CI for current HEAD |
| List-kind persistence and UI smoke | `PersistenceIntegrationTests.testListKindsPersistForTodoProjectAndReferenceLists` verifies todo/project/reference kinds; `ClarityHubUITests.testDenseFixtureRecordsRenderAcrossPrimaryAreas` verifies project-support and reference lists render with open counts | Covered by latest green iOS CI for current HEAD |
| Disk-backed persistence smoke | `PersistenceIntegrationTests.testDiskBackedStoreSurvivesContainerRecreationWithoutCloudKit` saves every V1 app-owned record type into a local non-CloudKit store, recreates the container, and fetches the records again | Covered by latest green iOS CI for current HEAD |
| HealthKit empty/denied smoke | `HealthKitStoreInjectionTests` verifies injectable HealthKit stores; `ClarityHubUITests.testHealthKitEmptyStateCopyRendersInBodyAndNutrition` and `testHealthKitDeniedStateCopyRendersInSetupBodyAndNutrition` render empty and denied HealthKit states in the app shell | Covered by latest green iOS CI for current HEAD |
| HealthKit unavailable smoke | `HealthKitStoreInjectionTests` verifies injected availability; `ClarityHubUITests.testHealthKitUnavailableStateCopyRendersInSetupBodyAndNutrition` renders unsupported-device HealthKit copy in Setup, Body, and Nutrition | Covered by latest green iOS CI for current HEAD |
| HealthKit sample-data smoke | `ClarityHubUITests.testHealthKitSampleDataRendersBodyTodayAndNutritionSignals` launches a DEBUG HealthKit fixture with seven weight samples and Apple Health nutrition totals, then verifies Today, Body, and Nutrition render current weight, goal delta, moving average, streak, and saved Health nutrition metrics | Covered by latest green iOS CI for current HEAD |
| Google disconnected smoke | `ClarityHubUITests.testGoogleDisconnectedStateRendersWithoutCalendarAPIAccess` launches blank OAuth settings with a fail-if-called Google Calendar client and verifies Today, Settings, and Calendar disconnected states; `GoogleCalendarIntegrationTests` and preference tests verify invalid redirect URIs are not treated as configured and normalize back to the app default | Covered by latest green iOS CI for current HEAD |
| Reminder controls smoke | `WeighInReminderSchedulerTests` verify daily/snooze request construction, notification category/action metadata, action routing to snooze/skip behavior, explicit pending-request cancellation before rescheduling, and cancellation identifiers; `ClarityHubUITests.testReminderScheduleSnoozeSkipControlsRenderSuccessStates` taps Body and Settings schedule, snooze, and skip controls with an authorized reminder fixture and verifies Today shows the reminder as scheduled | Covered by latest green iOS CI for current HEAD |
| Google connected fixture smoke | `ClarityHubUITests.testGoogleConnectedFixtureRendersEventsAndCreatesBlock` launches configured OAuth settings with a fixture access token and fixture Google Calendar client, then verifies Today/Calendar event rendering and Calendar block creation | Covered by latest green iOS CI for current HEAD |
| App relaunch persistence smoke | `ClarityHubUITests.testPersistentStoreSurvivesAppRelaunch` launches a debug-only disk-backed store, seeds dense V1 records, terminates the app, relaunches without reseeding, and verifies Today, Goals, Nutrition, and Review still render the saved records | Covered by latest green iOS CI for current HEAD |
| Nutrition import workflow smoke | `NutritionImportParserTests` cover label-before-value, value-before-label, comma-formatted, and alternate-label totals; `ClarityHubUITests.testNutritionImportFlowUpdatesTodaySignal` launches Nutrition with DEBUG-prefilled Cal AI-style totals, parses them through the visible UI, saves the day, verifies the recent average, and confirms Today's nutrition signal updates | Covered by latest green iOS CI for current HEAD |
| Visual acceptance evidence | Light/dark tab smoke and dense Today smoke attach XCTest screenshots; iOS CI uploads `TestResults/ClarityHub.xcresult` as a retained artifact; `.\scripts\v1-local-status.ps1` prints the latest retained artifact | Review latest retained artifact for current HEAD |
| Core data-entry workflow smoke | `ClarityHubUITests.testCoreDataEntryFlowCreatesRecordsAcrossPrimaryAreas` creates a goal, habit/check-in, list, project, task completion/restore, daily review, and weekly review through the visible UI and attaches screenshots | Covered by latest green iOS CI for current HEAD |

## Manual Acceptance

Manual acceptance must be executed with `docs/V1_ACCEPTANCE_RUNBOOK.md`.

| Manual area | Status |
| --- | --- |
| Light/dark tab pass | Partially automated by UI smoke; CI screenshots are uploaded for review; still needs human visual acceptance |
| Empty states | Setup sections are partially automated by UI smoke; CI screenshots are uploaded for review; empty-state copy still needs human visual acceptance |
| Long text | Partially automated by dense fixture UI smoke and data-entry screenshot evidence; still needs human visual acceptance |
| Dense Today data | Partially automated by dense Today UI smoke, nutrition import update smoke, core data-entry smoke, and CI screenshot artifact; still needs human visual acceptance |
| No HealthKit data | Partially automated by HealthKit empty-state UI smoke; still needs device/manual HealthKit acceptance |
| Denied HealthKit/notification permissions | Partially automated by HealthKit denied-state UI smoke and reminder scheduler tests; still needs device/manual permission acceptance |
| Positive HealthKit data | Partially automated by HealthKit sample-data UI smoke; still needs device/manual HealthKit acceptance with real Apple Health data |
| Google disconnected | Partially automated by disconnected-state UI smoke with fail-if-called Google Calendar client; still needs manual acceptance |
| Google connected with real OAuth credentials | Needs evidence; fixture smoke covers connected UI and API-client path, but not real Google consent |
| Reminder schedule/snooze/skip | Partially automated by scheduler/action unit tests and reminder controls UI smoke; still needs device/manual notification delivery acceptance |
| Relaunch persistence | Automated by disk-backed SwiftData recreation test, app-shell relaunch UI smoke, and visible data-entry smoke; still needs human acceptance for release-device behavior |
| Cal AI/manual nutrition import | Automated by parser tests and app-shell import/save/Today-signal UI smoke; still needs human acceptance for real copied Cal AI text variants |
| Private CloudKit two-device sync | Needs evidence |

## Completion Rule

V1 can be marked complete only when:

1. All local release-candidate commits are pushed.
2. GitHub Actions billing/spending-limit is fixed or avoided by the public repo configuration.
3. Latest `main` CI for the pushed HEAD is green.
4. `docs/V1_ACCEPTANCE_RUNBOOK.md` is executed on iPhone or simulator.
5. `.\scripts\test-v1-acceptance-record.ps1` passes for the filled acceptance record.
6. All manual defects are fixed or explicitly deferred outside V1.
7. Loop status is clean after the final release-candidate commit.

The filled acceptance record must be generated from the same pushed candidate that is manually tested. If any release-candidate commit changes after manual acceptance starts, rerun `.\scripts\start-v1-acceptance.ps1` and repeat or refresh the affected manual evidence before marking V1 complete.
