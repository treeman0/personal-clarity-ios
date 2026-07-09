import ClarityHubCore
import Foundation
import HealthKit

enum HealthKitAuthorizationRequestStatus: Equatable, Sendable {
    case shouldRequest
    case unnecessary
}

enum HealthKitClientError: Error, Equatable, Sendable {
    case authorizationDenied
}

enum HealthKitOperationFailure: Error, Equatable, Sendable {
    case timedOut
    case healthKit
}

enum HealthKitAuthorizationOutcome: Equatable, Sendable {
    case ready
    case denied
    case unavailable
    case failed(HealthKitOperationFailure)
}

enum HealthKitDataOutcome<Value: Equatable & Sendable>: Equatable, Sendable {
    case success(Value)
    case empty
    case denied
    case unavailable
    case failed(HealthKitOperationFailure)
}

struct HealthKitClient: Sendable {
    let isAvailable: @Sendable () -> Bool
    let authorizationRequestStatus: @Sendable () async throws -> HealthKitAuthorizationRequestStatus
    let requestAuthorization: @Sendable () async throws -> Void
    let fetchWeights: @Sendable (Date) async throws -> [WeightEntry]
    let fetchTodayNutrition: @Sendable (Calendar) async throws -> NutritionDay?

    init(
        isAvailable: @escaping @Sendable () -> Bool,
        authorizationRequestStatus: @escaping @Sendable () async throws -> HealthKitAuthorizationRequestStatus,
        requestAuthorization: @escaping @Sendable () async throws -> Void,
        fetchWeights: @escaping @Sendable (Date) async throws -> [WeightEntry],
        fetchTodayNutrition: @escaping @Sendable (Calendar) async throws -> NutritionDay?
    ) {
        self.isAvailable = isAvailable
        self.authorizationRequestStatus = authorizationRequestStatus
        self.requestAuthorization = requestAuthorization
        self.fetchWeights = fetchWeights
        self.fetchTodayNutrition = fetchTodayNutrition
    }

    static func live() -> HealthKitClient {
        let context = LiveHealthKitContext(readTypes: requiredReadTypes())

        return HealthKitClient(
            isAvailable: { HKHealthStore.isHealthDataAvailable() },
            authorizationRequestStatus: {
                try await withCheckedThrowingContinuation { continuation in
                    context.healthStore.getRequestStatusForAuthorization(toShare: [], read: context.readTypes) { status, error in
                        if let error {
                            continuation.resume(throwing: error)
                            return
                        }
                        continuation.resume(returning: status == .shouldRequest ? .shouldRequest : .unnecessary)
                    }
                }
            },
            requestAuthorization: {
                try await withCheckedThrowingContinuation { continuation in
                    context.healthStore.requestAuthorization(toShare: [], read: context.readTypes) { success, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else if success {
                            continuation.resume()
                        } else {
                            continuation.resume(throwing: HealthKitClientError.authorizationDenied)
                        }
                    }
                }
            },
            fetchWeights: { startDate in
                try await Self.fetchWeights(since: startDate, healthStore: context.healthStore)
            },
            fetchTodayNutrition: { calendar in
                try await Self.fetchTodayNutrition(calendar: calendar, healthStore: context.healthStore)
            }
        )
    }

    private static func requiredReadTypes() -> Set<HKObjectType> {
        [
            HKQuantityType.quantityType(forIdentifier: .bodyMass),
            HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            HKQuantityType.quantityType(forIdentifier: .dietaryProtein),
            HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates),
            HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)
        ].compactMap { $0 }.reduce(into: Set<HKObjectType>()) { $0.insert($1) }
    }

    private static func fetchWeights(since startDate: Date, healthStore: HKHealthStore) async throws -> [WeightEntry] {
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

    private static func fetchTodayNutrition(
        calendar: Calendar,
        healthStore: HKHealthStore
    ) async throws -> NutritionDay? {
        let start = calendar.startOfDay(for: Date())
        async let calories = sum(.dietaryEnergyConsumed, unit: .kilocalorie(), start: start, healthStore: healthStore)
        async let protein = sum(.dietaryProtein, unit: .gram(), start: start, healthStore: healthStore)
        async let carbs = sum(.dietaryCarbohydrates, unit: .gram(), start: start, healthStore: healthStore)
        async let fat = sum(.dietaryFatTotal, unit: .gram(), start: start, healthStore: healthStore)
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

private final class LiveHealthKitContext: @unchecked Sendable {
    let healthStore = HKHealthStore()
    let readTypes: Set<HKObjectType>

    init(readTypes: Set<HKObjectType>) {
        self.readTypes = readTypes
    }
}

actor HealthKitAuthorizationCoordinator {
    private let client: HealthKitClient
    private let timeoutNanoseconds: UInt64
    private var authorizationTask: Task<HealthKitAuthorizationOutcome, Never>?
    private var authorizationCompleted = false

    init(
        client: HealthKitClient = .live(),
        timeoutNanoseconds: UInt64 = 20_000_000_000
    ) {
        self.client = client
        self.timeoutNanoseconds = timeoutNanoseconds
    }

    func authorize() async -> HealthKitAuthorizationOutcome {
        guard client.isAvailable() else { return .unavailable }
        if authorizationCompleted { return .ready }
        if let authorizationTask { return await authorizationTask.value }

        let client = client
        let timeoutNanoseconds = timeoutNanoseconds
        let task = Task {
            await Self.performAuthorization(client: client, timeoutNanoseconds: timeoutNanoseconds)
        }
        authorizationTask = task
        let outcome = await task.value
        authorizationTask = nil
        if outcome == .ready {
            authorizationCompleted = true
        }
        return outcome
    }

    func loadWeights(requestAuthorization: Bool) async -> HealthKitDataOutcome<[WeightEntry]> {
        guard client.isAvailable() else { return .unavailable }
        if requestAuthorization {
            let authorization = await authorize()
            guard authorization == .ready else { return Self.dataOutcome(from: authorization) }
        }

        let start = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        let client = client
        do {
            let entries = try await Self.withTimeout(nanoseconds: timeoutNanoseconds) {
                try await client.fetchWeights(start)
            }
            return entries.isEmpty ? .empty : .success(entries)
        } catch {
            return Self.dataOutcome(from: error)
        }
    }

    func loadTodayNutrition(requestAuthorization: Bool) async -> HealthKitDataOutcome<NutritionDay> {
        guard client.isAvailable() else { return .unavailable }
        if requestAuthorization {
            let authorization = await authorize()
            guard authorization == .ready else { return Self.dataOutcome(from: authorization) }
        }

        let client = client
        do {
            let day = try await Self.withTimeout(nanoseconds: timeoutNanoseconds) {
                try await client.fetchTodayNutrition(.current)
            }
            if let day {
                return .success(day)
            }
            return .empty
        } catch {
            return Self.dataOutcome(from: error)
        }
    }

    private static func performAuthorization(
        client: HealthKitClient,
        timeoutNanoseconds: UInt64
    ) async -> HealthKitAuthorizationOutcome {
        do {
            let status = try await withTimeout(nanoseconds: timeoutNanoseconds) {
                try await client.authorizationRequestStatus()
            }
            if status == .shouldRequest {
                try await withTimeout(nanoseconds: timeoutNanoseconds) {
                    try await client.requestAuthorization()
                }
            }
            return .ready
        } catch {
            if isAuthorizationDenied(error) { return .denied }
            if error as? HealthKitOperationFailure == .timedOut { return .failed(.timedOut) }
            return .failed(.healthKit)
        }
    }

    private static func dataOutcome<Value>(
        from authorization: HealthKitAuthorizationOutcome
    ) -> HealthKitDataOutcome<Value> where Value: Equatable & Sendable {
        switch authorization {
        case .ready:
            return .failed(.healthKit)
        case .denied:
            return .denied
        case .unavailable:
            return .unavailable
        case let .failed(failure):
            return .failed(failure)
        }
    }

    private static func dataOutcome<Value>(
        from error: Error
    ) -> HealthKitDataOutcome<Value> where Value: Equatable & Sendable {
        if isAuthorizationDenied(error) {
            return .denied
        }
        if error as? HealthKitOperationFailure == .timedOut {
            return .failed(.timedOut)
        }
        return .failed(.healthKit)
    }

    private static func withTimeout<Value: Sendable>(
        nanoseconds: UInt64,
        operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        let operationTask = Task { try await operation() }
        return try await withCheckedThrowingContinuation { continuation in
            let gate = ContinuationGate(continuation)
            Task {
                do {
                    gate.resume(with: .success(try await operationTask.value))
                } catch {
                    gate.resume(with: .failure(error))
                }
            }
            Task {
                do {
                    try await Task.sleep(nanoseconds: nanoseconds)
                } catch {
                    return
                }
                gate.resume(with: .failure(HealthKitOperationFailure.timedOut))
                operationTask.cancel()
            }
        }
    }

    private static func isAuthorizationDenied(_ error: Error) -> Bool {
        if error as? HealthKitClientError == .authorizationDenied {
            return true
        }
        return (error as? HKError)?.code == .errorAuthorizationDenied
    }
}

private final class ContinuationGate<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Error>?

    init(_ continuation: CheckedContinuation<Value, Error>) {
        self.continuation = continuation
    }

    func resume(with result: Result<Value, Error>) {
        lock.lock()
        let continuation = continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(with: result)
    }
}
