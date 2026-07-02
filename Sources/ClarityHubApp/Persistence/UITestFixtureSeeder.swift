import Foundation
import SwiftData

#if DEBUG
enum UITestFixtureSeeder {
    @MainActor
    static func seedIfRequested(in container: ModelContainer) throws {
        guard ProcessInfo.processInfo.environment["CLARITYHUB_UI_TEST_FIXTURE"] == "dense" else {
            return
        }

        let context = container.mainContext
        let existingGoals = try context.fetch(FetchDescriptor<GoalRecord>())
        if existingGoals.contains(where: { $0.title == "Reach 180 lb with steady weekly gain" }) {
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        let listID = UUID()
        let projectID = UUID()
        let goalID = UUID()
        let checkedHabitID = UUID()
        let pendingHabitID = UUID()

        context.insert(AppPreferenceRecord(
            key: AppPreferenceKey.goalWeightPounds.rawValue,
            value: "180"
        ))
        context.insert(AppPreferenceRecord(
            key: AppPreferenceKey.weighInReminderHour.rawValue,
            value: "7"
        ))
        context.insert(AppPreferenceRecord(
            key: AppPreferenceKey.weighInReminderMinute.rawValue,
            value: "30"
        ))
        context.insert(AppPreferenceRecord(
            key: AppPreferenceKey.weighInReminderScheduled.rawValue,
            value: "true"
        ))
        context.insert(AppPreferenceRecord(
            key: AppPreferenceKey.googleCalendarClientID.rawValue,
            value: "ui-test-client-id.apps.googleusercontent.com"
        ))
        context.insert(AppPreferenceRecord(
            key: AppPreferenceKey.googleCalendarRedirectURI.rawValue,
            value: AppPreferences.defaultGoogleRedirectURI
        ))

        context.insert(GoalRecord(
            id: goalID,
            title: "Reach 180 lb with steady weekly gain",
            startingValue: 162,
            currentValue: 169.5,
            targetValue: 180,
            directionRawValue: "increase",
            dueDate: nextWeek,
            createdAt: today
        ))
        context.insert(GoalRecord(
            title: "Keep weekly review completion above 90 percent",
            startingValue: 0,
            currentValue: 72,
            targetValue: 100,
            directionRawValue: "increase",
            dueDate: nextWeek,
            createdAt: today.addingTimeInterval(60)
        ))

        context.insert(HabitRecord(
            id: checkedHabitID,
            title: "Morning weigh-in and clarity scan",
            weekdayMask: 127,
            createdAt: today
        ))
        context.insert(HabitRecord(
            id: pendingHabitID,
            title: "Prepare high-protein breakfast before first work block",
            weekdayMask: 127,
            createdAt: today.addingTimeInterval(60)
        ))
        context.insert(HabitCheckInRecord(habitID: checkedHabitID, date: now))

        context.insert(ClarityListRecord(
            id: listID,
            title: "Today operating list",
            kind: "todo",
            createdAt: today
        ))
        context.insert(ProjectRecord(
            id: projectID,
            title: "Personal clarity V1 launch",
            desiredOutcome: "A working daily hub that survives dense real-life data without losing scanability.",
            createdAt: today
        ))
        context.insert(TaskRecord(
            listID: listID,
            goalID: goalID,
            projectID: projectID,
            title: "Write the focused next action with enough detail to test long text wrapping in the Today priority queue",
            dueDate: today,
            priority: 5,
            createdAt: today
        ))
        context.insert(TaskRecord(
            listID: listID,
            goalID: goalID,
            projectID: projectID,
            title: "Confirm nutrition import and calendar block before evening review",
            dueDate: tomorrow,
            priority: 4,
            createdAt: today.addingTimeInterval(60)
        ))
        context.insert(TaskRecord(
            listID: listID,
            goalID: goalID,
            projectID: projectID,
            title: "Completed dense fixture task",
            status: "done",
            dueDate: today,
            priority: 2,
            createdAt: today.addingTimeInterval(120)
        ))

        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            context.insert(NutritionDayRecord(
                date: date,
                calories: 2825 + Double(offset * 15),
                proteinGrams: 170 + Double(offset),
                carbohydrateGrams: 310 - Double(offset * 2),
                fatGrams: 82 + Double(offset),
                source: offset == 0 ? "Cal AI import" : "Manual import"
            ))
        }

        context.insert(DailyReviewRecord(
            date: now,
            wins: "The dense fixture has a realistic amount of competing information.",
            friction: "Long labels need to stay readable without breaking the main operating screen.",
            nextFocus: "Protect the first training-support block and complete the highest priority clarity task."
        ))
        context.insert(WeeklyReviewRecord(
            weekStart: calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? today,
            keepDoing: "Keep using Today as the operating screen.",
            changeNextWeek: "Reduce repeated manual entry once integrations are proven.",
            focus: "Make V1 acceptance evidence concrete.",
            commitments: "Run the full device acceptance runbook."
        ))

        try context.save()
    }
}
#endif
