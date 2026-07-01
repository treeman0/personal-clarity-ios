# ClarityHub V1 Product Spec

## Purpose

ClarityHub keeps one person on track across the daily systems that affect clarity: body metrics, goals, habits, tasks, calendar, and nutrition.

## V1 Surfaces

- Today: current HealthKit weight state, goal progress, due habits, priority tasks, same-day Google Calendar blocks, and nutrition status.
- Setup: a Today checklist for body target, reminder, Google Calendar, first goal, first habit, task capture, and nutrition path.
- Body: HealthKit weight trend, goal weight comparison, moving average, weigh-in streak, and reminder snooze/skip controls.
- Goals: measurable goals with starting, current, and target values so progress reflects the actual distance from the point where the user began.
- Habits: daily and custom weekday habit cadence with due-today completion and scheduled habit visibility.
- Lists: todos, projects, and reusable lists, with task capture able to assign a next action to a list, project, and linked goal.
- Calendar: Google Calendar event context and block creation through the official API boundary.
- Nutrition: HealthKit nutrition totals first, manual/imported Cal AI daily totals second.
- Review: daily reflection plus weekly keep/change/focus/commitment review.

## Integration Policy

All integrations must be public, user-authorized, and App Store-compatible. V1 must not scrape Cal AI, automate private app UI, or depend on private APIs.

Release configuration that cannot be completed from unsigned CI is tracked in `docs/RELEASE_SETUP.md`.

## Google Calendar Setup

Google Calendar uses native OAuth with PKCE and the Google Calendar Events API for upcoming event reads and user-created block writes. A Google OAuth client ID must be entered in Settings before connecting. The default redirect URI is:

```text
com.treeman0.ClarityHub:/oauth2redirect/google
```

Tokens are stored in the device Keychain rather than CloudKit-backed preferences.

Today reuses the same token refresh path as Calendar and shows remaining same-day events as compact blocks. Calendar can create titled blocks on the primary Google calendar after user authorization. If Google Calendar is not configured or connected, Today shows the setup state without attempting private calendar access.

## Today Weight Behavior

Today loads the last 90 days of authorized Apple Health body-weight samples and uses the same trend calculator as Body. If HealthKit is not authorized or has no samples, Today shows a clear empty state and keeps Body/Setup as the authorization path.

## Reminder Behavior

The morning weigh-in reminder uses local notifications with a configurable daily time. Body also exposes a one-shot snooze reminder and a skip action for pending snoozes.

## Verification Coverage

CI runs core Swift package tests plus the generated Xcode app scheme. The app scheme includes SwiftData integration tests for the V1 records, preference upserts, record mappings used by goal/task integrations, Google Calendar OAuth/API request behavior, and local notification request construction for weigh-in reminders. XCTest launches use an in-memory SwiftData container because CI builds are unsigned and cannot exercise private CloudKit entitlements.

App-hosted tests also verify release metadata for HealthKit usage strings, CloudKit remote-notification background mode, and the privacy manifest.
