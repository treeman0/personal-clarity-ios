# ClarityHub

ClarityHub is a native iPhone app for daily clarity across body weight, goals, habits, tasks, calendar, and nutrition.

V1 is personal-first and App Store-compatible:

- SwiftUI app with a Today-first operating view
- SwiftData models prepared for private CloudKit sync
- HealthKit integration for smart-scale body weight and nutrition totals
- Local morning weigh-in reminders
- Google Calendar API client boundary
- Cal AI-compatible nutrition import path through Apple Health or user-provided daily totals
- macOS GitHub Actions CI for Swift tests and Xcode builds

## Development

This repo is configured with `treeman0/claude-loop-system`. Start by checking the loop status:

```powershell
.\.claude\scripts\status-report.ps1
```

On macOS with Xcode and XcodeGen:

```bash
swift test
xcodegen generate
xcodebuild test -project ClarityHub.xcodeproj -scheme ClarityHub -destination "platform=iOS Simulator,name=iPhone 16" CODE_SIGNING_ALLOWED=NO
```

On Windows, edit and run repository-level validation where possible; GitHub Actions performs the macOS/iOS build.

