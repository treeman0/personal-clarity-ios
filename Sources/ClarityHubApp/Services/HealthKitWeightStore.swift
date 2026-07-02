import ClarityHubCore
import Foundation
import HealthKit

struct HealthKitWeightStore {
    private let isAvailableProvider: () -> Bool
    private let requestAuthorizationAction: () async throws -> Void
    private let fetchWeightsAction: (Date) async throws -> [WeightEntry]

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
            guard let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
            try await healthStore.requestAuthorization(toShare: [], read: [bodyMass])
        }
        fetchWeightsAction = { startDate in
            guard HKHealthStore.isHealthDataAvailable() else { return [] }
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

    init(
        isAvailable: @escaping () -> Bool,
        requestAuthorization: @escaping () async throws -> Void,
        fetchWeights: @escaping (Date) async throws -> [WeightEntry]
    ) {
        isAvailableProvider = isAvailable
        requestAuthorizationAction = requestAuthorization
        fetchWeightsAction = fetchWeights
    }

    func requestAuthorization() async throws {
        try await requestAuthorizationAction()
    }

    func fetchWeights(since startDate: Date) async throws -> [WeightEntry] {
        try await fetchWeightsAction(startDate)
    }
}
