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

    func testDiskBackedStoreSurvivesContainerRecreationWithoutCloudKit() throws {
        let storageName = "ClarityHubDiskBackedPersistence-\(UUID().uuidString)"
        let goalID = UUID()
        let habitID = UUID()
        let listID = UUID()
        let projectID = UUID()

        do {
            let container = try ClarityHubModelContainerFactory.make(
                configurationName: storageName,
                cloudKitSync: .disabled
            )
            let context = ModelContext(container)
            context.insert(GoalRecord(
                id: goalID,
                title: "Persisted goal",
                startingValue: 160,
                currentValue: 170,
                targetValue: 180,
                directionRawValue: "increase"
            ))
            context.insert(HabitRecord(id: habitID, title: "Persisted habit", weekdayMask: HabitRecord.dailyWeekdayMask))
            context.insert(HabitCheckInRecord(habitID: habitID, date: Date(), state: "done"))
            context.insert(ClarityListRecord(id: listID, title: "Persisted list", kind: "todo"))
            context.insert(ProjectRecord(id: projectID, title: "Persisted project", desiredOutcome: "Records survive relaunch."))
            context.insert(TaskRecord(
                listID: listID,
                goalID: goalID,
                projectID: projectID,
                title: "Persisted task",
                priority: 4
            ))
            context.insert(NutritionDayRecord(
                date: Date(),
                calories: 2_900,
                proteinGrams: 175,
                carbohydrateGrams: 320,
                fatGrams: 85,
                source: "Manual import"
            ))
            context.insert(DailyReviewRecord(date: Date(), wins: "Saved", friction: "None", nextFocus: "Reload"))
            context.insert(WeeklyReviewRecord(
                weekStart: Date(),
                keepDoing: "Persist data",
                changeNextWeek: "Verify sync",
                focus: "Relaunch evidence",
                commitments: "Open the app again"
            ))
            context.insert(AppPreferenceRecord(key: AppPreferenceKey.goalWeightPounds.rawValue, value: "180"))
            try context.save()
        }

        do {
            let container = try ClarityHubModelContainerFactory.make(
                configurationName: storageName,
                cloudKitSync: .disabled
            )
            let context = ModelContext(container)

            XCTAssertEqual(try context.fetch(FetchDescriptor<GoalRecord>()).map(\.title), ["Persisted goal"])
            XCTAssertEqual(try context.fetch(FetchDescriptor<HabitRecord>()).map(\.title), ["Persisted habit"])
            XCTAssertEqual(try context.fetch(FetchDescriptor<HabitCheckInRecord>()).map(\.habitID), [habitID])
            XCTAssertEqual(try context.fetch(FetchDescriptor<ClarityListRecord>()).map(\.title), ["Persisted list"])
            XCTAssertEqual(try context.fetch(FetchDescriptor<ProjectRecord>()).map(\.title), ["Persisted project"])
            XCTAssertEqual(try context.fetch(FetchDescriptor<TaskRecord>()).map(\.title), ["Persisted task"])
            XCTAssertEqual(try context.fetch(FetchDescriptor<NutritionDayRecord>()).map(\.source), ["Manual import"])
            XCTAssertEqual(try context.fetch(FetchDescriptor<DailyReviewRecord>()).map(\.nextFocus), ["Reload"])
            XCTAssertEqual(try context.fetch(FetchDescriptor<WeeklyReviewRecord>()).map(\.focus), ["Relaunch evidence"])
            XCTAssertEqual(try context.fetch(FetchDescriptor<AppPreferenceRecord>()).map(\.value), ["180"])
        }
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

    func testPreferencesUpsertUpdatesDuplicateRecordsForSameKey() throws {
        let container = try ClarityHubModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        context.insert(AppPreferenceRecord(key: AppPreferenceKey.weighInReminderHour.rawValue, value: "6"))
        context.insert(AppPreferenceRecord(key: AppPreferenceKey.weighInReminderHour.rawValue, value: "7"))
        context.insert(AppPreferenceRecord(key: AppPreferenceKey.weighInReminderMinute.rawValue, value: "30"))
        try context.save()

        let preferences = try context.fetch(FetchDescriptor<AppPreferenceRecord>())
        AppPreferences.upsert(.weighInReminderHour, value: "8", in: context, preferences: preferences)
        try context.save()

        let saved = try context.fetch(FetchDescriptor<AppPreferenceRecord>())
        let matchingHours = saved.filter { $0.key == AppPreferenceKey.weighInReminderHour.rawValue }
        let matchingMinutes = saved.filter { $0.key == AppPreferenceKey.weighInReminderMinute.rawValue }

        XCTAssertEqual(matchingHours.map(\.value), ["8", "8"])
        XCTAssertEqual(matchingMinutes.map(\.value), ["30"])
    }

    func testGoogleRedirectNormalizationFallsBackToDefaultForBlankValues() {
        XCTAssertEqual(AppPreferences.normalizedGoogleRedirectURI(""), AppPreferences.defaultGoogleRedirectURI)
        XCTAssertEqual(AppPreferences.normalizedGoogleRedirectURI("   \n"), AppPreferences.defaultGoogleRedirectURI)
    }

    func testGoogleRedirectNormalizationFallsBackToDefaultForInvalidValues() {
        XCTAssertEqual(AppPreferences.normalizedGoogleRedirectURI("not a redirect uri"), AppPreferences.defaultGoogleRedirectURI)
        XCTAssertEqual(AppPreferences.normalizedGoogleRedirectURI("://missing-scheme"), AppPreferences.defaultGoogleRedirectURI)
    }

    func testGoogleRedirectNormalizationPreservesExplicitValues() {
        XCTAssertEqual(
            AppPreferences.normalizedGoogleRedirectURI("  com.example.ClarityHub:/oauth2redirect/google  "),
            "com.example.ClarityHub:/oauth2redirect/google"
        )
    }

    func testBooleanPreferenceRequiresExplicitTrueValue() {
        let preferences = [
            AppPreferenceRecord(key: AppPreferenceKey.weighInReminderScheduled.rawValue, value: "true"),
            AppPreferenceRecord(key: AppPreferenceKey.googleCalendarClientID.rawValue, value: "client")
        ]

        XCTAssertTrue(AppPreferences.boolean(.weighInReminderScheduled, in: preferences))
        XCTAssertFalse(AppPreferences.boolean(.googleCalendarClientID, in: preferences))
        XCTAssertFalse(AppPreferences.boolean(.weighInReminderHour, in: preferences))
    }

    func testHabitWeekdayMaskPreservesWeeklyCadence() {
        let mondayWednesdayFridayMask = [2, 4, 6].reduce(0) { $0 | (1 << ($1 - 1)) }
        let habit = HabitRecord(title: "Lift", weekdayMask: mondayWednesdayFridayMask)

        XCTAssertEqual(habit.weekdays, Set([2, 4, 6]))
        XCTAssertFalse(habit.isDaily)
    }

    func testDeletingHabitRemovesItsCheckInsOnly() throws {
        let container = try ClarityHubModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        let habitID = UUID()
        let otherHabitID = UUID()
        let habit = HabitRecord(id: habitID, title: "Morning weigh-in", weekdayMask: HabitRecord.dailyWeekdayMask)

        context.insert(habit)
        context.insert(HabitRecord(id: otherHabitID, title: "Lift", weekdayMask: HabitRecord.dailyWeekdayMask))
        context.insert(HabitCheckInRecord(habitID: habitID, date: Date(), state: "done"))
        context.insert(HabitCheckInRecord(habitID: habitID, date: Date().addingTimeInterval(-86_400), state: "done"))
        context.insert(HabitCheckInRecord(habitID: otherHabitID, date: Date(), state: "done"))
        try context.save()

        let checkIns = try context.fetch(FetchDescriptor<HabitCheckInRecord>())
        checkIns
            .filter { $0.habitID == habit.id }
            .forEach(context.delete)
        context.delete(habit)
        try context.save()

        let remainingHabits = try context.fetch(FetchDescriptor<HabitRecord>())
        let remainingCheckIns = try context.fetch(FetchDescriptor<HabitCheckInRecord>())

        XCTAssertEqual(remainingHabits.map(\.id), [otherHabitID])
        XCTAssertEqual(remainingCheckIns.map(\.habitID), [otherHabitID])
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

    func testListKindsPersistForTodoProjectAndReferenceLists() throws {
        let container = try ClarityHubModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        context.insert(ClarityListRecord(title: "Today", kind: "todo"))
        context.insert(ClarityListRecord(title: "Launch support", kind: "project"))
        context.insert(ClarityListRecord(title: "Nutrition reference", kind: "reference"))

        try context.save()

        let lists = try context.fetch(FetchDescriptor<ClarityListRecord>())
        let kindsByTitle = Dictionary(uniqueKeysWithValues: lists.map { ($0.title, $0.kind) })

        XCTAssertEqual(kindsByTitle["Today"], "todo")
        XCTAssertEqual(kindsByTitle["Launch support"], "project")
        XCTAssertEqual(kindsByTitle["Nutrition reference"], "reference")
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

    func testReplacingNutritionDayLeavesOneRecordForThatDay() throws {
        let container = try ClarityHubModelContainerFactory.make(inMemory: true)
        let context = ModelContext(container)
        let calendar = Calendar(identifier: .gregorian)
        let selectedDay = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 1, hour: 18)))
        let sameDayMorning = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 1, hour: 7)))
        let previousDay = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 30, hour: 18)))

        context.insert(NutritionDayRecord(
            date: sameDayMorning,
            calories: 2_400,
            proteinGrams: 140,
            carbohydrateGrams: 260,
            fatGrams: 70,
            source: "Manual import"
        ))
        context.insert(NutritionDayRecord(
            date: previousDay,
            calories: 2_700,
            proteinGrams: 160,
            carbohydrateGrams: 300,
            fatGrams: 80,
            source: "Cal AI import"
        ))
        try context.save()

        let existingRecords = try context.fetch(FetchDescriptor<NutritionDayRecord>())
        RecordDateMatcher.records(existingRecords, on: selectedDay, calendar: calendar) { $0.date }
            .forEach(context.delete)
        context.insert(NutritionDayRecord(
            date: selectedDay,
            calories: 3_000,
            proteinGrams: 180,
            carbohydrateGrams: 320,
            fatGrams: 90,
            source: "Apple Health"
        ))
        try context.save()

        let savedRecords = try context.fetch(FetchDescriptor<NutritionDayRecord>())
        let selectedDayRecords = RecordDateMatcher.records(savedRecords, on: selectedDay, calendar: calendar) { $0.date }
        let previousDayRecords = RecordDateMatcher.records(savedRecords, on: previousDay, calendar: calendar) { $0.date }

        XCTAssertEqual(savedRecords.count, 2)
        XCTAssertEqual(selectedDayRecords.map(\.calories), [3_000])
        XCTAssertEqual(selectedDayRecords.map(\.source), ["Apple Health"])
        XCTAssertEqual(previousDayRecords.map(\.calories), [2_700])
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
