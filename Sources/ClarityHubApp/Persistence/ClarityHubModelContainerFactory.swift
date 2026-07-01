import SwiftData

enum ClarityHubModelContainerFactory {
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            GoalRecord.self,
            HabitRecord.self,
            HabitCheckInRecord.self,
            ClarityListRecord.self,
            TaskRecord.self,
            ProjectRecord.self,
            NutritionDayRecord.self,
            DailyReviewRecord.self,
            WeeklyReviewRecord.self,
            AppPreferenceRecord.self
        ])

        let configuration = ModelConfiguration(
            "ClarityHub",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : .private("iCloud.com.treeman0.ClarityHub")
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
