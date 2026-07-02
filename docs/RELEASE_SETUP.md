# ClarityHub Release Setup

## Apple Capabilities

Before TestFlight or App Store submission, configure the app identifier for `com.treeman0.ClarityHub` with:

- HealthKit
- iCloud with CloudKit
- iCloud container `iCloud.com.treeman0.ClarityHub`
- Push Notifications capability required by CloudKit remote notifications

The repository declares the matching HealthKit and iCloud entitlements in `Sources/ClarityHubApp/ClarityHub.entitlements`, and declares `remote-notification` background mode in `Sources/ClarityHubApp/Info.plist`.

CI runs `scripts/verify-release-config.sh` to check that the checked-in HealthKit entitlement, CloudKit service, iCloud container, Google OAuth callback scheme, Xcode entitlements path, and SwiftData private CloudKit container stay aligned.

## Privacy

The app bundle includes `Sources/ClarityHubApp/PrivacyInfo.xcprivacy`. V1 declares no tracking and uses collected data only for app functionality:

- Health: body weight and nutrition values authorized through Apple Health.
- Fitness: weight trend and habit/body progress signals.
- Other user content: goals, habits, tasks, lists, projects, reviews, and imported nutrition text.
- Product interaction: app-owned progress and setup state.

App Store Connect privacy answers must match the privacy manifest and the actual enabled integrations.

V1 only reads authorized HealthKit data. It must not declare `NSHealthUpdateUsageDescription` or request HealthKit write access unless a future version adds a real Apple Health write path.

## Google Calendar

Create an iOS OAuth client for the app bundle ID and configure the redirect URI:

```text
com.treeman0.ClarityHub:/oauth2redirect/google
```

V1 requests the Google Calendar Events scope:

```text
https://www.googleapis.com/auth/calendar.events
```

This scope is used for reading upcoming events and creating user-requested calendar blocks.

## Device Acceptance

Run the full V1 checklist in `docs/V1_ACCEPTANCE.md` and record evidence with `docs/V1_ACCEPTANCE_RUNBOOK.md` on iPhone or simulator before TestFlight. At minimum, cover:

- Light and dark mode.
- Empty states.
- Long goal/task/habit text.
- No HealthKit data.
- Denied HealthKit and notification permissions.
- Dense Today data.
- Google Calendar connect, refresh, and create-block flows with real OAuth credentials.
