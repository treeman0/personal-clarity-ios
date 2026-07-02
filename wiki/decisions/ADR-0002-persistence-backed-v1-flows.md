# ADR-0002: Persistence-Backed V1 Flows

## Status

Accepted.

## Decision

ClarityHub V1 app-owned workflows use SwiftData records directly in SwiftUI screens for goals, habits, tasks, nutrition imports, and daily reviews.

## Context

The initial shell used preview data to prove the app shape and CI build. V1 needs to be personally usable, so daily actions must persist through the configured SwiftData and private CloudKit-ready model container.

## Consequences

- Today now reflects stored goals, habits, tasks, nutrition, authorized HealthKit weight, and same-day Google Calendar blocks instead of only sample data.
- Today next actions are backed by `TaskRecord` IDs so the operating screen can show list/project/goal context and complete tasks in place.
- Goals, daily/custom weekday habits, task capture, dated nutrition import/history, daily review, and weekly review have first write paths.
- Goal records store a starting value separately from current and target values so progress remains meaningful after the user updates the current value.
- Goals can create linked next actions directly, and those actions flow into Lists and Today through the shared task model.
- Task capture can attach a task to an existing list, project, and goal, and Today surfaces goal context in next actions.
- Weigh-in reminders use local notifications with a daily repeating request plus a one-shot snooze request that can be skipped from Body.
- HealthKit body weight remains an external authorized source and is automatically refreshed into Body/Today views rather than copied into app-owned storage.
- SwiftData model properties declare defaults so the schema is friendlier to private CloudKit sync and future lightweight migration.
- Weight goal and morning reminder preferences are stored through `AppPreferenceRecord` and surfaced in Settings instead of being hard-coded in feature views.
- Google Calendar OAuth configuration lives in Settings while OAuth tokens live in Keychain; calendar events are fetched and user-created blocks are inserted through Google's Events API instead of preview data when connected.
- Google Calendar token refresh is shared by Calendar and Today so both surfaces use the same public, user-authorized API boundary.
- Today includes a setup checklist so first-run readiness is visible in the primary operating surface rather than hidden across tabs.
- The Xcode scheme includes app-level SwiftData integration tests for V1 records, preferences, and mapping fields in addition to core package tests.
- Google Calendar app tests use injected transport to verify OAuth scopes, event-list requests, event-create requests, and non-success API errors without live network calls.
- Weigh-in reminder tests use injected notification operations and static request builders to verify authorization options, daily triggers, snooze triggers, and cancellation IDs without prompting CI for notification permission.
- XCTest launches use an in-memory app container so unsigned CI builds do not attempt to initialize private CloudKit before tests execute.
- Release metadata tests verify HealthKit usage descriptions, CloudKit remote-notification background mode, and the bundled privacy manifest; Apple/Google console setup remains documented in `docs/RELEASE_SETUP.md`.
