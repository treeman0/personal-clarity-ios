# ClarityHub V1 Completion Audit

This audit maps the original V1 requirements to the evidence needed before the goal can be marked complete. Treat anything marked `Needs evidence` or `Blocked` as incomplete.

## Current Release Candidate

Update this block when performing a final V1 audit. Do not treat stale commit IDs as evidence.

```text
Current local HEAD: run `git log -1 --oneline`
Current remote HEAD: run `git log -1 --oneline origin/main`
Current local/remote status: run `git status -sb`
Latest CI status: run `gh run list --repo treeman0/personal-clarity-ios --branch main --limit 3`
Manual acceptance: not executed
Goal status: active, not complete
```

Known state as of 2026-07-02: the repository is public and GitHub Actions can start hosted macOS jobs without the previous private-repository billing block.

On Windows, run `.\scripts\v1-local-status.ps1` to collect the local status, loop gate, release verifier, Swift availability, and latest GitHub Actions summary in one pass.

## Workflow Requirements

| Requirement | Evidence | Status |
| --- | --- | --- |
| New repo named `personal-clarity-ios` | GitHub repo `treeman0/personal-clarity-ios` and local worktree | Achieved |
| `treeman0/claude-loop-system` installed with Codex flow | `AGENTS.md`, `.claude-loop.json`, `.agents/skills/`, `.codex/loop.md`, `.codex/config.toml`, `.codex/hooks.json`, `.codex/hooks/`, `wiki/`; loop status report | Achieved |
| Loop defaults enabled | `.claude/scripts/status-report.ps1` reports TDD, verification gate, wiki memory/gate, skill tracking, manual review, safety guard, status report enabled | Achieved |
| macOS CI runs Swift tests and Xcode builds on push/PR | `.github/workflows/ios-ci.yml`; latest pushed commit must have a green `iOS CI` run | Achieved, rerun status before final acceptance |
| Windows local development does not require Xcode | Local Windows gates run release verifier and loop status; macOS CI is authoritative for Swift/Xcode | Achieved with caveat |

## Product Requirements

| Area | Requirement | Evidence | Status |
| --- | --- | --- | --- |
| App shell | Native SwiftUI iPhone app with Today, Body, Goals, Habits, Lists, Calendar, Nutrition, Review, Settings | `RootTabView.swift`, generated Xcode CI build, `ClarityHubUITests` light/dark tab smoke | Achieved, needs full manual UI pass |
| Setup | Today setup checklist for defaults, core permissions, reminder scheduling, and denied notification feedback | `SetupChecklistView.swift`, reminder tests | Needs manual UI pass |
| Persistence | SwiftData with private CloudKit for app-owned data | `ClarityHubModelContainerFactory.swift`, entitlements, release verifier, disk-backed persistence recreation test, latest green CI | Needs signed-device sync smoke |
| Body | HealthKit body weight, goal comparison, trend chart, moving average, unique-day weigh-in streak | `HealthKitWeightStore.swift`, `BodyView.swift`, weight tests | Needs device/manual HealthKit pass |
| Reminders | Morning weigh-in reminders with configurable time, permission-denied handling, snooze, skip | `WeighInReminderScheduler.swift`, tests, Body/Settings UI | Needs device/manual notification pass |
| Goals | Measurable goals, increase/decrease/maintain progress, optional due dates, current-value update, linked next actions, linked-task cleanup on delete | `GoalsView.swift`, goal progress and persistence tests | Needs manual UI pass |
| Habits | Daily/custom weekday habits, completion, cadence-aware streaks, delete with check-ins | `HabitsView.swift`, `HabitScheduleTests.swift`, persistence tests | Needs manual UI pass |
| Lists/projects | Todo/project/reference lists, project outcomes, priority/due/list/project/goal task capture, completed-task review, restore, and cleanup | `ListsView.swift`, task planner and persistence tests | Needs manual UI pass |
| Calendar | Google OAuth PKCE/consent, official Calendar API read/write, upcoming-window reads, direct disconnect, clear states | `CalendarView.swift`, `GoogleOAuthClient.swift`, `GoogleCalendarClient.swift`, tests | Needs real Google OAuth manual pass |
| Nutrition | Apple Health nutrition totals or Cal AI/manual import, comma-formatted import parsing, stale import clearing, history, averages, same-day replace/delete | `NutritionHealthStore.swift`, `NutritionView.swift`, parser/summary and persistence tests | Needs device/manual nutrition pass |
| Today | Operating screen integrates setup, weight, focus, goals, habits, tasks, calendar, nutrition | `TodayDashboardView.swift`, latest green CI, dense-data `ClarityHubUITests` fixture | Needs manual dense-data pass |
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
| `git diff --check` | Passes on the current Windows worktree | Passed locally |
| `bash scripts/verify-release-config.sh` | Passes on the current Windows worktree | Passed locally |
| `.claude/scripts/status-report.ps1` | Passes with all loop defaults enabled | Passed locally |
| `.\scripts\v1-local-status.ps1` | Reports local/remote state, loop status, release verifier, Swift availability, and latest Actions runs | Passed locally |
| `swift test` | Not available on Windows host | Needs macOS |
| `xcodegen generate` | Not available on Windows host | Needs macOS |
| `xcodebuild test ...` | Not available on Windows host | Needs macOS |
| Latest `main` CI green | Run `gh run list --repo treeman0/personal-clarity-ios --branch main --limit 3` and confirm the latest run for `origin/main` succeeded | Passed for latest checked state; rerun before final acceptance |
| Light/dark app-shell and setup-section smoke | `ClarityHubUITests.testV1SurfacesRenderInLightAndDarkMode` runs in the app scheme on macOS CI | Added; needs latest CI evidence |
| Dense fixture smoke | `ClarityHubUITests.testDenseTodayDataRendersInLightAndDarkMode` and `testDenseFixtureRecordsRenderAcrossPrimaryAreas` launch an in-memory fixture with goals, habits, long tasks, lists/projects, nutrition, preferences, and review focus | Added; needs latest CI evidence |
| Disk-backed persistence smoke | `PersistenceIntegrationTests.testDiskBackedStoreSurvivesContainerRecreationWithoutCloudKit` saves every V1 app-owned record type into a local non-CloudKit store, recreates the container, and fetches the records again | Added; needs latest CI evidence |
| HealthKit empty/denied smoke | `HealthKitStoreInjectionTests` verifies injectable HealthKit stores; `ClarityHubUITests.testHealthKitEmptyStateCopyRendersInBodyAndNutrition` and `testHealthKitDeniedStateCopyRendersInSetupBodyAndNutrition` render empty and denied HealthKit states in the app shell | Added; needs latest CI evidence |
| Google disconnected smoke | `ClarityHubUITests.testGoogleDisconnectedStateRendersWithoutCalendarAPIAccess` launches blank OAuth settings with a fail-if-called Google Calendar client and verifies Today, Settings, and Calendar disconnected states | Added; needs latest CI evidence |
| Reminder controls smoke | `WeighInReminderSchedulerTests` verify daily/snooze request construction and cancellation identifiers; `ClarityHubUITests.testReminderScheduleSnoozeSkipControlsRenderSuccessStates` taps Body and Settings schedule, snooze, and skip controls with an authorized reminder fixture | Added; needs latest CI evidence |
| Google connected fixture smoke | `ClarityHubUITests.testGoogleConnectedFixtureRendersEventsAndCreatesBlock` launches configured OAuth settings with a fixture access token and fixture Google Calendar client, then verifies Today/Calendar event rendering and Calendar block creation | Added; needs latest CI evidence |
| App relaunch persistence smoke | `ClarityHubUITests.testPersistentStoreSurvivesAppRelaunch` launches a debug-only disk-backed store, seeds dense V1 records, terminates the app, relaunches without reseeding, and verifies Today, Goals, Nutrition, and Review still render the saved records | Added; needs latest CI evidence |
| Nutrition import workflow smoke | `ClarityHubUITests.testNutritionImportFlowUpdatesTodaySignal` enters Cal AI-style totals in Nutrition, parses them, saves the day, verifies the recent average, and confirms Today's nutrition signal updates | Added; needs latest CI evidence |

## Manual Acceptance

Manual acceptance must be executed with `docs/V1_ACCEPTANCE_RUNBOOK.md`.

| Manual area | Status |
| --- | --- |
| Light/dark tab pass | Partially automated by UI smoke; still needs human visual acceptance |
| Empty states | Setup sections are partially automated by UI smoke; empty-state copy still needs human visual acceptance |
| Long text | Partially automated by dense fixture UI smoke; still needs human visual acceptance |
| Dense Today data | Partially automated by dense Today UI smoke and nutrition import update smoke; still needs human visual acceptance |
| No HealthKit data | Partially automated by HealthKit empty-state UI smoke; still needs device/manual HealthKit acceptance |
| Denied HealthKit/notification permissions | Partially automated by HealthKit denied-state UI smoke and reminder scheduler tests; still needs device/manual permission acceptance |
| Google disconnected | Partially automated by disconnected-state UI smoke with fail-if-called Google Calendar client; still needs manual acceptance |
| Google connected with real OAuth credentials | Needs evidence; fixture smoke covers connected UI and API-client path, but not real Google consent |
| Reminder schedule/snooze/skip | Partially automated by scheduler unit tests and reminder controls UI smoke; still needs device/manual notification acceptance |
| Relaunch persistence | Automated by disk-backed SwiftData recreation test and app-shell relaunch UI smoke; still needs human acceptance for release-device behavior |
| Cal AI/manual nutrition import | Automated by parser tests and app-shell import/save/Today-signal UI smoke; still needs human acceptance for real copied Cal AI text variants |
| Private CloudKit two-device sync | Needs evidence |

## Completion Rule

V1 can be marked complete only when:

1. All local release-candidate commits are pushed.
2. GitHub Actions billing/spending-limit is fixed or avoided by the public repo configuration.
3. Latest `main` CI for the pushed HEAD is green.
4. `docs/V1_ACCEPTANCE_RUNBOOK.md` is executed on iPhone or simulator.
5. All manual defects are fixed or explicitly deferred outside V1.
6. Loop status is clean after the final release-candidate commit.
