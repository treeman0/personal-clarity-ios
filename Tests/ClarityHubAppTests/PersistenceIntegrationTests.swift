import Foundation
import SwiftData
import XCTest
@testable import ClarityHub

final class PersistenceIntegrationTests: XCTestCase {
    func testInMemoryModelContainerPersistsV1Records() throws {
        let container = try ClarityHubModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        let goalID = UUID()
        let habitID = UUID()
        let listID = UUID()
        let projectID = UUID()

        context.insert(GoalRecord(
            id: goalID,
            title: "Gain weight",
            startingValue: 165,
            currentValue: 170,
            targetValue: 180,
            directionRawValue: "increase"
        ))
        context.insert(HabitRecord(id: habitID, title: "Morning weigh-in", weekdayMask: HabitRecord.dailyWeekdayMask))
        context.insert(HabitCheckInRecord(habitID: habitID, date: Date(), state: "done"))
        context.insert(ClarityListRecord(id: listID, title: "Today", kind: "todo"))
        context.insert(ProjectRecord(id: projectID, title: "V1 launch", desiredOutcome: "Ship a usable personal app"))
        context.insert(TaskRecord(
            listID: listID,
            goalID: goalID,
            projectID: projectID,
            title: "Plan training meal",
            priority: 3
        ))
        context.insert(NutritionDayRecord(
            date: Date(),
            calories: 2800,
            proteinGrams: 170,
            carbohydrateGrams: 300,
            fatGrams: 80,
            source: "Manual import"
        ))
        context.insert(DailyReviewRecord(date: Date(), wins: "Moved forward", friction: "", nextFocus: "Weight"))
        context.insert(WeeklyReviewRecord(
            weekStart: Date(),
            keepDoing: "Morning review",
            changeNextWeek: "Plan earlier",
            focus: "Ship V1",
            commitments: "Lift three times"
        ))
        context.insert(AppPreferenceRecord(key: AppPreferenceKey.goalWeightPounds.rawValue, value: "180"))

        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<GoalRecord>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<HabitRecord>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<HabitCheckInRecord>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<ClarityListRecord>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<TaskRecord>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<ProjectRecord>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<NutritionDayRecord>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<DailyReviewRecord>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<WeeklyReviewRecord>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<AppPreferenceRecord>()).count, 1)
    }

    func testPreferencesUpsertInsertsAndUpdatesSingleRecord() throws {
        let container = try ClarityHubModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)

        AppPreferences.upsert(.goalWeightPounds, value: "185", in: context, preferences: [])
        try context.save()

        var preferences = try context.fetch(FetchDescriptor<AppPreferenceRecord>())
        XCTAssertEqual(preferences.count, 1)
        XCTAssertEqual(AppPreferences.double(.goalWeightPounds, in: preferences, default: 180), 185)

        AppPreferences.upsert(.goalWeightPounds, value: "190", in: context, preferences: preferences)
        try context.save()

        preferences = try context.fetch(FetchDescriptor<AppPreferenceRecord>())
        XCTAssertEqual(preferences.count, 1)
        XCTAssertEqual(AppPreferences.double(.goalWeightPounds, in: preferences, default: 180), 190)
    }

    func testGoogleRedirectNormalizationFallsBackToDefaultForBlankValues() {
        XCTAssertEqual(AppPreferences.normalizedGoogleRedirectURI(""), AppPreferences.defaultGoogleRedirectURI)
        XCTAssertEqual(AppPreferences.normalizedGoogleRedirectURI("   \n"), AppPreferences.defaultGoogleRedirectURI)
    }

    func testGoogleRedirectNormalizationPreservesExplicitValues() {
        XCTAssertEqual(
            AppPreferences.normalizedGoogleRedirectURI("  com.example.ClarityHub:/oauth2redirect/google  "),
            "com.example.ClarityHub:/oauth2redirect/google"
        )
    }

    func testHabitWeekdayMaskPreservesWeeklyCadence() {
        let mondayWednesdayFridayMask = [2, 4, 6].reduce(0) { $0 | (1 << ($1 - 1)) }
        let habit = HabitRecord(title: "Lift", weekdayMask: mondayWednesdayFridayMask)

        XCTAssertEqual(habit.weekdays, Set([2, 4, 6]))
        XCTAssertFalse(habit.isDaily)
    }

    func testGoalLinkedTaskCanBeFetchedByGoalID() throws {
        let container = try ClarityHubModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        let goalID = UUID()
        context.insert(GoalRecord(
            id: goalID,
            title: "Gain weight",
            startingValue: 165,
            currentValue: 170,
            targetValue: 180,
            directionRawValue: "increase"
        ))
        context.insert(TaskRecord(goalID: goalID, title: "Buy training groceries", priority: 2))

        try context.save()

        let tasks = try context.fetch(FetchDescriptor<TaskRecord>())
        let linkedTasks = tasks.filter { $0.goalID == goalID && $0.status == "open" }

        XCTAssertEqual(linkedTasks.map(\.title), ["Buy training groceries"])
    }

    func testDeletingGoalRemovesLinkedTasksOnly() throws {
        let container = try ClarityHubModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        let goalID = UUID()
        let otherGoalID = UUID()

        let goal = GoalRecord(
            id: goalID,
            title: "Gain weight",
            startingValue: 165,
            currentValue: 170,
            targetValue: 180,
            directionRawValue: "increase"
        )
        context.insert(goal)
        context.insert(GoalRecord(
            id: otherGoalID,
            title: "Improve sleep",
            startingValue: 6,
            currentValue: 7,
            targetValue: 8,
            directionRawValue: "increase"
        ))
        context.insert(TaskRecord(goalID: goalID, title: "Buy training groceries", priority: 2))
        context.insert(TaskRecord(goalID: goalID, title: "Plan breakfast", priority: 2))
        context.insert(TaskRecord(goalID: otherGoalID, title: "Set wind-down alarm", priority: 1))
        context.insert(TaskRecord(title: "Unlinked admin task", priority: 0))
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<TaskRecord>())
        tasks
            .filter { $0.goalID == goal.id }
            .forEach(context.delete)
        context.delete(goal)
        try context.save()

        let remainingGoals = try context.fetch(FetchDescriptor<GoalRecord>())
        let remainingTasks = try context.fetch(FetchDescriptor<TaskRecord>())

        XCTAssertEqual(remainingGoals.map(\.id), [otherGoalID])
        XCTAssertEqual(Set(remainingTasks.map(\.title)), Set(["Set wind-down alarm", "Unlinked admin task"]))
    }

    func testTaskCompletionCanBeRestoredAndDeleted() throws {
        let container = try ClarityHubModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        let task = TaskRecord(title: "Plan training meal", priority: 3)
        context.insert(task)
        try context.save()

        task.status = "done"
        try context.save()

        var tasks = try context.fetch(FetchDescriptor<TaskRecord>())
        XCTAssertEqual(tasks.map(\.status), ["done"])

        task.status = "open"
        try context.save()

        tasks = try context.fetch(FetchDescriptor<TaskRecord>())
        XCTAssertEqual(tasks.map(\.status), ["open"])

        context.delete(task)
        try context.save()

        tasks = try context.fetch(FetchDescriptor<TaskRecord>())
        XCTAssertTrue(tasks.isEmpty)
    }

    func testDuplicateGoalTitlesKeepDistinctRecordIdentity() throws {
        let container = try ClarityHubModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        let firstID = UUID()
        let secondID = UUID()

        context.insert(GoalRecord(
            id: firstID,
            title: "Gain weight",
            startingValue: 165,
            currentValue: 170,
            targetValue: 180,
            directionRawValue: "increase"
        ))
        context.insert(GoalRecord(
            id: secondID,
            title: "Gain weight",
            startingValue: 0,
            currentValue: 1,
            targetValue: 3,
            directionRawValue: "increase"
        ))

        try context.save()

        let goals = try context.fetch(FetchDescriptor<GoalRecord>())

        XCTAssertEqual(Set(goals.map(\.id)), Set([firstID, secondID]))
        XCTAssertEqual(goals.map(\.title).filter { $0 == "Gain weight" }.count, 2)
    }

    func testRecordMappingsPreserveGoalAndTaskIntegrationFields() {
        let goalID = UUID()
        let listID = UUID()
        let projectID = UUID()
        let dueDate = Date()
        let taskDueDate = dueDate.addingTimeInterval(86_400)
        let goal = GoalRecord(
            id: goalID,
            title: "Gain weight",
            startingValue: 165,
            currentValue: 170,
            targetValue: 180,
            directionRawValue: "increase",
            dueDate: dueDate
        )
        let task = TaskRecord(
            listID: listID,
            goalID: goalID,
            projectID: projectID,
            title: "Buy groceries",
            dueDate: taskDueDate,
            priority: 2
        )

        XCTAssertEqual(goal.snapshot.startingValue, 165)
        XCTAssertEqual(goal.snapshot.currentValue, 170)
        XCTAssertEqual(goal.snapshot.dueDate, dueDate)
        XCTAssertEqual(task.item.id, task.id)
        XCTAssertEqual(task.item.listID, listID)
        XCTAssertEqual(task.item.goalID, goalID)
        XCTAssertEqual(task.item.projectID, projectID)
        XCTAssertEqual(task.item.dueDate, taskDueDate)
        XCTAssertEqual(task.item.title, "Buy groceries")
    }

    func testRecordDateMatcherFindsReviewForSameCalendarDay() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 1, hour: 20)))
        let morning = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 1, hour: 7)))
        let yesterday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 30, hour: 22)))
        let reviews = [
            DailyReviewRecord(date: yesterday, wins: "Old", friction: "", nextFocus: "Old focus"),
            DailyReviewRecord(date: morning, wins: "Lifted", friction: "", nextFocus: "Plan breakfast")
        ]

        let matches = RecordDateMatcher.records(reviews, on: today, calendar: calendar) { $0.date }

        XCTAssertEqual(matches.map(\.nextFocus), ["Plan breakfast"])
    }

    func testReplacingDailyReviewLeavesOneReviewForTheDay() throws {
        let container = try ClarityHubModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        let calendar = Calendar(identifier: .gregorian)
        let morning = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 1, hour: 7)))
        let evening = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 1, hour: 20)))

        context.insert(DailyReviewRecord(date: morning, wins: "Started", friction: "Late", nextFocus: "Walk"))
        try context.save()

        let existingReviews = try context.fetch(FetchDescriptor<DailyReviewRecord>())
        RecordDateMatcher.records(existingReviews, on: evening, calendar: calendar) { $0.date }
            .forEach(context.delete)
        context.insert(DailyReviewRecord(date: evening, wins: "Finished", friction: "", nextFocus: "Plan lift"))
        try context.save()

        let savedReviews = try context.fetch(FetchDescriptor<DailyReviewRecord>())
        XCTAssertEqual(savedReviews.count, 1)
        XCTAssertEqual(savedReviews.first?.nextFocus, "Plan lift")
    }

    func testReplacingWeeklyReviewLeavesOneReviewForTheWeek() throws {
        let container = try ClarityHubModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        let calendar = Calendar(identifier: .gregorian)
        let weekStart = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 28)))

        context.insert(WeeklyReviewRecord(
            weekStart: weekStart,
            keepDoing: "Morning planning",
            changeNextWeek: "Prep earlier",
            focus: "Training",
            commitments: "Lift three times"
        ))
        try context.save()

        let existingReviews = try context.fetch(FetchDescriptor<WeeklyReviewRecord>())
        existingReviews
            .filter { calendar.isDate($0.weekStart, inSameDayAs: weekStart) }
            .forEach(context.delete)
        context.insert(WeeklyReviewRecord(
            weekStart: weekStart,
            keepDoing: "Morning weigh-in",
            changeNextWeek: "Shop earlier",
            focus: "Nutrition consistency",
            commitments: "Hit calories daily"
        ))
        try context.save()

        let savedReviews = try context.fetch(FetchDescriptor<WeeklyReviewRecord>())
        XCTAssertEqual(savedReviews.count, 1)
        XCTAssertEqual(savedReviews.first?.focus, "Nutrition consistency")
    }
}
