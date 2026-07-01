# V1 Architecture Decision

ClarityHub is implemented as a native SwiftUI iPhone app with a pure Swift core module.

- App-owned data uses SwiftData models prepared for private CloudKit sync.
- Weight and nutrition health data use HealthKit.
- Google Calendar is isolated behind a client boundary so OAuth and sync can evolve without leaking into UI code.
- Cal AI is integrated only through Apple Health or user-provided import/manual totals.
- CI runs on macOS because local development is Windows-first and iOS builds require Xcode.

