# ADR-0002: Persistence-Backed V1 Flows

## Status

Accepted.

## Decision

ClarityHub V1 app-owned workflows use SwiftData records directly in SwiftUI screens for goals, habits, tasks, nutrition imports, and daily reviews.

## Context

The initial shell used preview data to prove the app shape and CI build. V1 needs to be personally usable, so daily actions must persist through the configured SwiftData and private CloudKit-ready model container.

## Consequences

- Today now reflects stored goals, habits, tasks, and nutrition instead of only sample data.
- Goals, habits, task capture, nutrition import, and daily review have first write paths.
- HealthKit body weight remains an external authorized source and is refreshed on demand rather than copied into app-owned storage.

