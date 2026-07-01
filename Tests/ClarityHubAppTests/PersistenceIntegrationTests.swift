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
        context.insert(TaskRecord(listID: listID, goalID: goalID, title: "Plan training meal", priority: 3))
        context.insert(ProjectRecord(title: "V1 launch", desiredOutcome: "Ship a usable personal app"))
        context.insert(NutritionDayRecord(
            date: Date(),
            calories: 2800,
            proteinGrams: 170,
            carbohydrateGrams: 300,
            fatGrams: 80,
            source: "Manual import"
        ))
        context.insert(DailyReviewRecord(date: Date(), wins: "Moved forward", friction: "", nextFocus: "Weight"))
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

    func testRecordMappingsPreserveGoalAndTaskIntegrationFields() {
        let goalID = UUID()
        let goal = GoalRecord(
            id: goalID,
            title: "Gain weight",
            startingValue: 165,
            currentValue: 170,
            targetValue: 180,
            directionRawValue: "increase"
        )
        let task = TaskRecord(goalID: goalID, title: "Buy groceries", priority: 2)

        XCTAssertEqual(goal.snapshot.startingValue, 165)
        XCTAssertEqual(goal.snapshot.currentValue, 170)
        XCTAssertEqual(task.item.goalID, goalID)
        XCTAssertEqual(task.item.title, "Buy groceries")
    }
}
