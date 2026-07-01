import SwiftUI

private struct HealthKitWeightStoreKey: EnvironmentKey {
    static let defaultValue = HealthKitWeightStore()
}

private struct NutritionHealthStoreKey: EnvironmentKey {
    static let defaultValue = NutritionHealthStore()
}

private struct WeighInReminderSchedulerKey: EnvironmentKey {
    static let defaultValue = WeighInReminderScheduler()
}

private struct GoogleCalendarClientKey: EnvironmentKey {
    static let defaultValue = GoogleCalendarClient()
}

extension EnvironmentValues {
    var healthKitWeightStore: HealthKitWeightStore {
        get { self[HealthKitWeightStoreKey.self] }
        set { self[HealthKitWeightStoreKey.self] = newValue }
    }

    var nutritionHealthStore: NutritionHealthStore {
        get { self[NutritionHealthStoreKey.self] }
        set { self[NutritionHealthStoreKey.self] = newValue }
    }

    var weighInReminderScheduler: WeighInReminderScheduler {
        get { self[WeighInReminderSchedulerKey.self] }
        set { self[WeighInReminderSchedulerKey.self] = newValue }
    }

    var googleCalendarClient: GoogleCalendarClient {
        get { self[GoogleCalendarClientKey.self] }
        set { self[GoogleCalendarClientKey.self] = newValue }
    }
}

