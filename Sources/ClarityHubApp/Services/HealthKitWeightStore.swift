import ClarityHubCore
import Foundation
import HealthKit

struct HealthKitWeightStore {
    private let healthStore = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isAvailable else { return }
        guard let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        try await healthStore.requestAuthorization(toShare: [], read: [bodyMass])
    }

    func fetchWeights(since startDate: Date) async throws -> [WeightEntry] {
        guard isAvailable else { return [] }
        guard let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [.strictStartDate])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMass,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let entries = (samples as? [HKQuantitySample] ?? []).map {
                    WeightEntry(date: $0.startDate, pounds: $0.quantity.doubleValue(for: .pound()))
                }
                continuation.resume(returning: entries)
            }

            healthStore.execute(query)
        }
    }
}

