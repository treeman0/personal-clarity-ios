import ClarityHubCore
import Foundation

enum PreviewData {
    static let calendar = Calendar(identifier: .gregorian)
    static let now = Date()

    static var weights: [WeightEntry] {
        (0..<14).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else { return nil }
            return WeightEntry(date: date, pounds: 164.2 + Double(13 - offset) * 0.18)
        }
        .sorted { $0.date < $1.date }
    }

    static let goalWeight = 180.0

    static var weightTrend: WeightTrend {
        WeightTrendCalculator.trend(entries: weights, goalWeight: goalWeight, today: now, calendar: calendar)
    }

    static let goals = [
        GoalSnapshot(title: "Reach 180 lb", startingValue: 162, currentValue: 166.5, targetValue: 180, direction: .increase),
        GoalSnapshot(title: "Publish V1", startingValue: 0, currentValue: 42, targetValue: 100, direction: .increase),
        GoalSnapshot(title: "Deep work rhythm", startingValue: 2, currentValue: 4, targetValue: 5, direction: .increase)
    ]

    static let tasks = [
        TaskItem(title: "Review HealthKit permission copy", status: .open, dueDate: now, priority: 3),
        TaskItem(title: "Draft weekly review questions", status: .open, priority: 2),
        TaskItem(title: "Choose Google OAuth consent setup", status: .open, priority: 1)
    ]

    static let nutrition = NutritionDay(
        date: now,
        calories: 2840,
        proteinGrams: 172,
        carbohydrateGrams: 286,
        fatGrams: 92,
        source: "Manual import"
    )

    static var calendarEvents: [CalendarEvent] {
        [
            CalendarEvent(
                id: "morning-plan",
                title: "Morning planning",
                startDate: calendar.date(byAdding: .hour, value: 1, to: now) ?? now,
                endDate: calendar.date(byAdding: .hour, value: 2, to: now) ?? now,
                calendarName: "Personal"
            ),
            CalendarEvent(
                id: "training",
                title: "Training block",
                startDate: calendar.date(byAdding: .hour, value: 5, to: now) ?? now,
                endDate: calendar.date(byAdding: .hour, value: 6, to: now) ?? now,
                calendarName: "Health"
            )
        ]
    }

    static var dailySnapshot: DailyClaritySnapshot {
        DailyClaritySnapshot(
            date: now,
            weightTrend: weightTrend,
            goals: goals,
            habitsDue: 5,
            habitsDone: 3,
            openTasks: TaskPlanner.priorityQueue(tasks),
            nutrition: nutrition
        )
    }
}
