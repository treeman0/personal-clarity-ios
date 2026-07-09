# V2 Build Modes

ClarityHub V2 has two generated app targets. They share product code but intentionally use different storage and signing capabilities.

## Local mode: no paid Apple account

Use the `ClarityHubLocal` scheme for a Personal Team or simulator.

- Bundle ID: `com.treeman0.ClarityHub.Personal`
- Storage: device-local SwiftData
- Entitlements: HealthKit only
- Notifications: local notifications, including weigh-in reminders
- Google Calendar: supported with the Local redirect URI configured in Google Cloud
- Not included: CloudKit, APNs, iCloud sync, or remote-notification background mode

Generate the Xcode project with `xcodegen generate`, select `ClarityHubLocal`, choose the Personal Team in Signing & Capabilities, and run on the iPhone. This target is the supported no-cost V2 path; it is no longer maintained in a detached worktree.

## Cloud mode: paid Apple provisioning required

Use the `ClarityHub` scheme for the release configuration.

- Bundle ID: `com.treeman0.ClarityHub`
- Storage: private CloudKit-backed SwiftData
- Entitlements: HealthKit, CloudKit/iCloud, and APNs
- Notifications: local reminders plus CloudKit remote-notification support

The release target remains protected by `scripts/verify-release-config.sh`. The combined V2 guard is `scripts/verify-v2-config.sh`.

## HealthKit behavior

Both modes use one shared authorization coordinator. Body weight and nutrition read permissions are requested together, repeated requests are coalesced, and authorization and data queries have a 20-second deadline. Setup, Body, Nutrition, and Today show progress and always settle into success, empty, denied, unavailable, timeout, or failure presentation.

Apple does not reveal whether individual read permissions were denied. A completed authorization request followed by no samples is therefore presented as an empty-or-permission state with a path to Health settings.

## V1 blockers retained

Formal V1 acceptance remains incomplete. The exact release candidate still needs physical-device HealthKit verification, delivered notification Snooze/Skip verification, live Google OAuth and token lifecycle verification, two-device private CloudKit sync, and paid provisioning for the CloudKit/APNs target. The Local target does not count as evidence for those release-candidate checks.
