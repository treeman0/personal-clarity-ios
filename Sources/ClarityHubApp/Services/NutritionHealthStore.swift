import ClarityHubCore
import Foundation
import HealthKit

struct NutritionHealthStore {
    private let isAvailableProvider: () -> Bool
    private let requestAuthorizationAction: () async throws -> Void
    private let fetchTodayNutritionAction: (Calendar) async throws -> NutritionDay?

    var isAvailable: Bool {
        isAvailableProvider()
    }

    init() {
        let healthStore = HKHealthStore()
        isAvailableProvider = {
            HKHealthStore.isHealthDataAvailable()
        }
        requestAuthorizationAction = {
            guard HKHealthStore.isHealthDataAvailable() else { return }
            let readTypes = NutritionHealthStore.nutritionTypes()
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        }
        fetchTodayNutritionAction = { calendar in
            guard HKHealthStore.isHealthDataAvailable() else { return nil }
            let start = calendar.startOfDay(for: Date())
            async let calories = NutritionHealthStore.sum(
                .dietaryEnergyConsumed,
                unit: .kilocalorie(),
                start: start,
                healthStore: healthStore
            )
            async let protein = NutritionHealthStore.sum(
                .dietaryProtein,
                unit: .gram(),
                start: start,
                healthStore: healthStore
            )
            async let carbs = NutritionHealthStore.sum(
                .dietaryCarbohydrates,
                unit: .gram(),
                start: start,
                healthStore: healthStore
            )
            async let fat = NutritionHealthStore.sum(
                .dietaryFatTotal,
                unit: .gram(),
                start: start,
                healthStore: healthStore
            )

            let totals = try await (calories, protein, carbs, fat)
            guard totals.0 > 0 || totals.1 > 0 || totals.2 > 0 || totals.3 > 0 else { return nil }

            return NutritionDay(
                date: start,
                calories: totals.0,
                proteinGrams: totals.1,
                carbohydrateGrams: totals.2,
                fatGrams: totals.3,
                source: "Apple Health"
            )
        }
    }

    init(
        isAvailable: @escaping () -> Bool = { true },
        requestAuthorization: @escaping () async throws -> Void,
        fetchTodayNutrition: @escaping (Calendar) async throws -> NutritionDay?
    ) {
        isAvailableProvider = isAvailable
        requestAuthorizationAction = requestAuthorization
        fetchTodayNutritionAction = fetchTodayNutrition
    }

    func requestAuthorization() async throws {
        try await requestAuthorizationAction()
    }

    func fetchTodayNutrition(calendar: Calendar = .current) async throws -> NutritionDay? {
        try await fetchTodayNutritionAction(calendar)
    }

    private static func nutritionTypes() -> Set<HKObjectType> {
        [
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein),
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates),
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)
        ].compactMap { $0 }.reduce(into: Set<HKObjectType>()) { $0.insert($1) }
    }

    private static func sum(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        healthStore: HKHealthStore
    ) async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: [.strictStartDate])

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }

            healthStore.execute(query)
        }
    }
}
