# ClarityHub V1 Acceptance

This checklist defines the evidence needed before declaring V1 complete. Automated CI proves build, unit, integration, release-configuration, and app-scheme checks. Device acceptance still needs a real iPhone or macOS simulator because this Windows workspace cannot run Xcode or iOS Simulator.

## Automated Gates

Run before any V1 release candidate:

```bash
swift test
bash scripts/verify-release-config.sh
xcodegen generate
xcodebuild test -project ClarityHub.xcodeproj -scheme ClarityHub -destination "platform=iOS Simulator,name=iPhone 16" CODE_SIGNING_ALLOWED=NO
```

Current GitHub Actions CI runs these checks on macOS except that `xcodegen generate` happens before the Xcode build/test commands. On Windows, `swift test` is not available unless a Swift toolchain is installed.

## Product Acceptance

- Today: shows setup readiness, current HealthKit weight state or empty state, latest review focus, goal progress, due habit count, priority next actions with due-date/list/project/goal context, recent nutrition average, same-day Google Calendar blocks, and nutrition status.
- Body: can request HealthKit access, refresh Apple Health body weight, show empty state when no samples exist, show current/goal/average/streak metrics, render raw and moving-average chart with goal rule, schedule daily reminder, snooze reminder, and skip snooze.
- Goals: can create measurable increase/decrease/maintain goals with optional due date, update current value directly, show progress, capture linked next actions, complete linked actions, and delete a goal with linked tasks.
- Habits: can create daily and custom weekday habits, prevent empty weekday schedules, complete/uncomplete due-today habits, show cadence-aware streaks, show all scheduled habits, and delete habits with check-ins.
- Lists: can create todo/project/reference lists, create projects with desired outcomes, capture tasks with priority, due date, list, project, and goal, sort by shared planner priority/due-date behavior, complete tasks from Lists, and surface projects/lists with open counts.
- Calendar: can save Google OAuth settings, start native OAuth with PKCE, refresh upcoming Google Calendar events, create a focus block on the primary calendar, and show clear not-configured/not-connected/error states.
- Nutrition: can request HealthKit nutrition access, save Apple Health totals if present, parse Cal AI/manual text imports, replace an existing same-day record, delete records, show recent history, and show recent calorie/macro averages in Nutrition and Today.
- Review: can save one daily review per day, create a deduplicated next-focus task due tomorrow, save/update the current weekly review, and show recent daily/weekly review history.
- Settings: can persist goal weight, weigh-in reminder time, Google OAuth client ID, and redirect URI, and can schedule the daily reminder from saved settings.

## Manual Device Matrix

Run on iPhone or iOS Simulator before calling V1 complete:

- Light mode: navigate all tabs, verify controls and text remain legible.
- Dark mode: navigate all tabs, verify controls and text remain legible.
- Empty state: new in-memory or clean install state shows useful empty states on Today, Body, Goals, Habits, Lists, Calendar, Nutrition, and Review.
- Long text: create long goal, habit, task, project outcome, review, and calendar block titles; verify rows wrap or scale without overlap.
- Dense daily data: create multiple goals, due habits, priority tasks, calendar blocks, nutrition days, and reviews; verify Today remains scannable and actionable.
- No HealthKit data: authorize HealthKit on a device/account with no body-weight or nutrition samples; verify Body/Today/Nutrition empty states.
- Denied permissions: deny HealthKit and notification permissions; verify Body, Setup, Settings, and Nutrition show clear non-crashing status messages.
- Google disconnected: leave OAuth settings blank, then save settings without connecting; verify Today and Calendar do not attempt private calendar access.
- Google connected: use real OAuth credentials to connect, refresh events, create a focus block, then verify the block exists in Google Calendar.
- Reminder behavior: schedule the morning reminder, snooze it from Body, skip the pending snooze, and verify no duplicate pending snooze remains.
- Persistence and sync smoke: create records across all app-owned surfaces, relaunch, and confirm data persists; on two signed-in devices with iCloud enabled, confirm private CloudKit sync when release signing is available.

## Completion Rule

V1 can be called complete only after the latest `main` CI run is green, the loop status report has no pending gates, this acceptance checklist has been executed for the release candidate, and any manual acceptance defects are either fixed or explicitly deferred outside V1.
