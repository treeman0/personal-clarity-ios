# ClarityHub V1 Product Spec

## Purpose

ClarityHub keeps one person on track across the daily systems that affect clarity: body metrics, goals, habits, tasks, calendar, and nutrition.

## V1 Surfaces

- Today: current weight state, goal progress, due habits, priority tasks, next events, and nutrition status.
- Body: HealthKit weight trend, goal weight comparison, moving average, and weigh-in streak.
- Goals: measurable goals with linked habits, tasks, and weekly review prompts.
- Habits: daily and weekly habit cadence with streaks and completion windows.
- Lists: todos, projects, and reusable lists.
- Calendar: Google Calendar event context through the official API boundary.
- Nutrition: HealthKit nutrition totals first, manual/imported Cal AI daily totals second.
- Review: daily reflection and weekly progress review.

## Integration Policy

All integrations must be public, user-authorized, and App Store-compatible. V1 must not scrape Cal AI, automate private app UI, or depend on private APIs.

