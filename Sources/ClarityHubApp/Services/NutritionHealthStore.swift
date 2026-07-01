import ClarityHubCore
import Foundation
import HealthKit

struct NutritionHealthStore {
    private let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let readTypes = nutritionTypes()
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    func fetchTodayNutrition(calendar: Calendar = .current) async throws -> NutritionDay? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        let start = calendar.startOfDay(for: Date())
        async let calories = sum(.dietaryEnergyConsumed, unit: .kilocalorie(), start: start)
        async let protein = sum(.dietaryProtein, unit: .gram(), start: start)
        async let carbs = sum(.dietaryCarbohydrates, unit: .gram(), start: start)
        async let fat = sum(.dietaryFatTotal, unit: .gram(), start: start)

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

    private func nutritionTypes() -> Set<HKObjectType> {
        [
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein),
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates),
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)
        ].compactMap { $0 }.reduce(into: Set<HKObjectType>()) { $0.insert($1) }
    }

    private func sum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date) async throws -> Double {
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

