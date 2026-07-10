# ADR-0003: V2 Local and Cloud Build Modes

## Decision

Generate two iOS application targets from the shared SwiftUI source tree.

- `ClarityHub` is the release target and keeps private CloudKit, APNs, HealthKit, and `com.treeman0.ClarityHub`.
- `ClarityHubLocal` is the no-cost Personal Team target and uses local SwiftData, HealthKit only, and `com.treeman0.ClarityHub.Personal`.

The compile condition `CLARITYHUB_LOCAL` selects local persistence and the Local Google OAuth callback. A configuration verifier checks that Local mode never acquires iCloud, CloudKit, APNs, or remote-notification declarations.

## Rationale

Personal Teams cannot provision the release target's iCloud and Push Notifications capabilities. A first-class generated target keeps useful on-device development and daily use available without weakening or mutating the release configuration.

HealthKit authorization is also centralized in one coordinator for both targets. The coordinator requests all required read types together, coalesces repeated requests, and bounds every authorization and query operation so UI state cannot remain loading indefinitely.

## Consequences

Local data does not sync through iCloud and is not release-candidate acceptance evidence. Google OAuth clients must register the redirect URI matching the selected target. Both generated schemes must build in CI, while the release scheme remains the full UI-test gate.

V2 Local completion uses a separate evidence path from formal V1 acceptance. `install_v2_local_device.sh` builds, signs, installs, and launches only the Local target with a Personal Team. `new_v2_local_acceptance_record.py` captures candidate, CI, configuration, and security state; `validate_v2_local_acceptance.py` requires real iPhone HealthKit, delivered reminder, and relaunch-persistence evidence before V2 Local can be accepted. Device build logs remain local and ignored so hardware identifiers and developer paths are not published.
