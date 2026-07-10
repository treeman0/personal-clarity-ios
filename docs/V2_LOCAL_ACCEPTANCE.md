# ClarityHub V2 Local Acceptance

This is the focused completion gate for the no-cost V2 target. It does not mark V1 accepted and does not claim release-target CloudKit, APNs, live Google OAuth, or two-device sync evidence.

## Automated preflight

The candidate must be committed, pushed, and have successful iOS CI and CodeQL runs. Generate the working record only after those runs complete:

```bash
python3 scripts/new_v2_local_acceptance_record.py
python3 scripts/validate_v2_local_acceptance.py
```

The validator is expected to fail until the physical-device fields are completed. Do not change `Accepted for V2 Local` to `yes` based on simulator fixtures.

## Build, install, and launch

Connect and unlock the iPhone, enable Developer Mode, trust the Mac, and confirm Xcode is signed into the Personal Team. Use the device destination ID reported by Xcode and the Personal Team identifier shown in Signing & Capabilities:

```bash
bash scripts/install_v2_local_device.sh \
  --device-id "<Xcode destination ID>" \
  --team-id "<Personal Team ID>"
```

The helper verifies a clean pushed candidate, verifies both build configurations, generates the Xcode project, builds only `ClarityHubLocal`, installs `com.treeman0.ClarityHub.Personal`, launches it, and writes `docs/evidence/v2-local-device-<sha>.log`. It deliberately does not run the full simulator suite again.

## Focused iPhone pass

Record every result in `docs/V2_LOCAL_ACCEPTANCE_RECORD.md` from real observation.

1. Open Settings and confirm Data mode shows `On this iPhone` and `Local storage, no iCloud sync`.
2. From Setup, tap Authorize once. Confirm one Health authorization flow includes both Body Measurements and Nutrition access and returns to ClarityHub without hanging.
3. Open Body. Confirm weight samples load, or a clear no-samples, denied, timeout, or failure state replaces progress within 20 seconds.
4. Open Nutrition and connect totals. Confirm saved totals or a clear terminal state replaces progress within 20 seconds.
5. Set the morning reminder a few minutes ahead, background the app, and confirm it is delivered with the Snooze 15 min action. Use Snooze, then confirm the snoozed notification exposes Skip snooze; clear it from the notification or Body and confirm no duplicate snooze remains.
6. Create a distinctive goal, habit, list, task, nutrition entry, and review. Force-quit ClarityHub Local, relaunch it, and confirm all records remain.
7. Capture screenshots of Data mode, the Health state, reminder state, and persisted data after relaunch.
8. Record any defect. A V2-blocking defect must be fixed before acceptance; `Open V2-blocking defects` must be `0`.

After filling the record, run:

```bash
python3 scripts/validate_v2_local_acceptance.py
```

V2 Local can be accepted only when this validator passes for the same commit as successful iOS CI and CodeQL runs.
