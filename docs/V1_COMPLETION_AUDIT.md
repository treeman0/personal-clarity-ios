# ClarityHub V1 Completion Audit

This audit maps the original V1 requirements to the evidence needed before the goal can be marked complete. Treat anything marked `Needs evidence` or `Blocked` as incomplete.

## Current Release Candidate

Update this block when performing a final V1 audit. Do not treat stale commit IDs as evidence.

```text
Local HEAD: run `git log -1 --oneline`
Remote HEAD: run `git log -1 --oneline origin/main`
Local/remote status: run `git status -sb`
Latest CI status: run `gh run list --repo treeman0/personal-clarity-ios --branch main --limit 3`
Manual acceptance: not executed
Goal status: active, not complete
```

Known state at the time this audit was added: local `main` was ahead of `origin/main`, and the latest remote CI run failed before job start because GitHub Actions reported an account billing/spending-limit issue.

On Windows, run `.\scripts\v1-local-status.ps1` to collect the local status, loop gate, release verifier, Swift availability, and latest GitHub Actions summary in one pass.

## Workflow Requirements

| Requirement | Evidence | Status |
| --- | --- | --- |
| New repo named `personal-clarity-ios` | GitHub repo `treeman0/personal-clarity-ios` and local worktree | Achieved |
| `treeman0/claude-loop-system` installed with Codex flow | `AGENTS.md`, `.claude-loop.json`, `.agents/skills/`, `.codex/loop.md`, `.codex/config.toml`, `.codex/hooks.json`, `.codex/hooks/`, `wiki/`; loop status report | Achieved |
| Loop defaults enabled | `.claude/scripts/status-report.ps1` reports TDD, verification gate, wiki memory/gate, skill tracking, manual review, safety guard, status report enabled | Achieved |
| macOS CI runs Swift tests and Xcode builds on push/PR | `.github/workflows/ios-ci.yml`; green run needed for latest pushed commit | Blocked by GitHub Actions billing |
| Windows local development does not require Xcode | Local Windows gates run release verifier and loop status; macOS CI is authoritative for Swift/Xcode | Achieved with caveat |

## Product Requirements

| Area | Requirement | Evidence | Status |
| --- | --- | --- | --- |
| App shell | Native SwiftUI iPhone app with Today, Body, Goals, Habits, Lists, Calendar, Nutrition, Review, Settings | `RootTabView.swift`, generated Xcode CI build | Needs latest CI rerun |
| Persistence | SwiftData with private CloudKit for app-owned data | `ClarityHubModelContainerFactory.swift`, entitlements, release verifier | Needs latest CI rerun and signed-device sync smoke |
| Body | HealthKit body weight, goal comparison, trend chart, moving average, streak | `HealthKitWeightStore.swift`, `BodyView.swift`, weight tests | Needs device/manual HealthKit pass |
| Reminders | Morning weigh-in reminders with configurable time, snooze, skip | `WeighInReminderScheduler.swift`, tests, Body/Settings UI | Needs device/manual notification pass |
| Goals | Measurable goals, optional due dates, current-value update, linked next actions | `GoalsView.swift`, persistence tests | Needs manual UI pass |
| Habits | Daily/custom weekday habits, completion, cadence-aware streaks, delete with check-ins | `HabitsView.swift`, `HabitScheduleTests.swift` | Needs manual UI pass |
| Lists/projects | Todo/project/reference lists, project outcomes, priority/due/list/project/goal task capture, completed-task review, restore, and cleanup | `ListsView.swift`, task planner and persistence tests | Needs manual UI pass |
| Calendar | Google OAuth PKCE, official Calendar API read/write, direct disconnect, clear states | `CalendarView.swift`, `GoogleOAuthClient.swift`, `GoogleCalendarClient.swift`, tests | Needs real Google OAuth manual pass |
| Nutrition | Apple Health nutrition totals or Cal AI/manual import, stale import clearing, history, averages, same-day replace/delete | `NutritionHealthStore.swift`, `NutritionView.swift`, parser/summary tests | Needs device/manual nutrition pass |
| Today | Operating screen integrates setup, weight, focus, goals, habits, tasks, calendar, nutrition | `TodayDashboardView.swift`, current local identity fix | Needs latest CI rerun and manual dense-data pass |
| Review | Daily/weekly reviews, same-day edit, next-focus task creation | `ReviewView.swift`, review planner and persistence tests | Needs manual UI pass |
| Settings | Goal weight, reminder time, Google OAuth settings, reminder scheduling | `SettingsView.swift`, preference tests | Needs manual UI pass |

## Integration Policy

| Requirement | Evidence | Status |
| --- | --- | --- |
| App Store-compatible public integrations only | Product spec, HealthKit/Google API implementation, no Cal AI scraping code | Achieved |
| Cal AI through Apple Health or user import only | `NutritionHealthStore.swift`, `NutritionImportParser.swift`, `NutritionView.swift` | Achieved, needs manual pass |
| Google tokens in Keychain, not CloudKit preferences | `KeychainTokenStore.swift`, `GoogleCalendarSession.swift`, product spec | Achieved |
| Read-only HealthKit metadata matches implementation | `Info.plist`, release verifier, release metadata tests | Achieved on prior CI; needs latest CI rerun |

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
| Latest `main` CI green | Latest remote run did not start jobs due billing/spending-limit | Blocked |

## Manual Acceptance

Manual acceptance must be executed with `docs/V1_ACCEPTANCE_RUNBOOK.md`.

| Manual area | Status |
| --- | --- |
| Light/dark tab pass | Needs evidence |
| Empty states | Needs evidence |
| Long text | Needs evidence |
| Dense Today data | Needs evidence |
| No HealthKit data | Needs evidence |
| Denied HealthKit/notification permissions | Needs evidence |
| Google disconnected | Needs evidence |
| Google connected with real OAuth credentials | Needs evidence |
| Reminder schedule/snooze/skip | Needs evidence |
| Relaunch persistence | Needs evidence |
| Private CloudKit two-device sync | Needs evidence |

## Completion Rule

V1 can be marked complete only when:

1. All local release-candidate commits are pushed.
2. GitHub Actions billing/spending-limit is fixed.
3. Latest `main` CI for the pushed HEAD is green.
4. `docs/V1_ACCEPTANCE_RUNBOOK.md` is executed on iPhone or simulator.
5. All manual defects are fixed or explicitly deferred outside V1.
6. Loop status is clean after the final release-candidate commit.
