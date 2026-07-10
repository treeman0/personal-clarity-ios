import SwiftData

enum ClarityHubModelContainerFactory {
    enum CloudKitSync: Equatable {
        case productionPrivate
        case disabled
    }

    static func make(
        inMemory: Bool = false,
        configurationName: String = "ClarityHub",
        cloudKitSync: CloudKitSync = .productionPrivate
    ) throws -> ModelContainer {
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

        let configuration: ModelConfiguration
        switch cloudKitSync {
        case .productionPrivate:
            configuration = ModelConfiguration(
                configurationName,
                schema: schema,
                isStoredInMemoryOnly: inMemory,
                cloudKitDatabase: inMemory ? .none : .private("iCloud.com.treeman0.ClarityHub")
            )
        case .disabled:
            configuration = ModelConfiguration(
                configurationName,
                schema: schema,
                isStoredInMemoryOnly: inMemory,
                cloudKitDatabase: .none
            )
        }

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
