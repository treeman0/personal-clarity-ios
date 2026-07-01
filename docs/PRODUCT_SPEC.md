# ClarityHub V1 Product Spec

## Purpose

ClarityHub keeps one person on track across the daily systems that affect clarity: body metrics, goals, habits, tasks, calendar, and nutrition.

## V1 Surfaces

- Today: current HealthKit weight state, goal progress, due habits, priority tasks, same-day Google Calendar blocks, and nutrition status.
- Setup: a Today checklist for body target, reminder, Google Calendar, first goal, first habit, task capture, and nutrition path.
- Body: HealthKit weight trend, goal weight comparison, moving average, and weigh-in streak.
- Goals: measurable goals with starting, current, and target values so progress reflects the actual distance from the point where the user began.
- Habits: daily and weekly habit cadence with streaks and completion windows.
- Lists: todos, projects, and reusable lists.
- Calendar: Google Calendar event context through the official API boundary.
- Nutrition: HealthKit nutrition totals first, manual/imported Cal AI daily totals second.
- Review: daily reflection and weekly progress review.

## Integration Policy

All integrations must be public, user-authorized, and App Store-compatible. V1 must not scrape Cal AI, automate private app UI, or depend on private APIs.

## Google Calendar Setup

Google Calendar uses native OAuth with PKCE and the Google Calendar `events.list` REST endpoint. A Google OAuth client ID must be entered in Settings before connecting. The default redirect URI is:

```text
com.treeman0.ClarityHub:/oauth2redirect/google
```

Tokens are stored in the device Keychain rather than CloudKit-backed preferences.

Today reuses the same token refresh path as Calendar and shows remaining same-day events as compact blocks. If Google Calendar is not configured or connected, Today shows the setup state without attempting private calendar access.

## Today Weight Behavior

Today loads the last 90 days of authorized Apple Health body-weight samples and uses the same trend calculator as Body. If HealthKit is not authorized or has no samples, Today shows a clear empty state and keeps Body/Setup as the authorization path.
