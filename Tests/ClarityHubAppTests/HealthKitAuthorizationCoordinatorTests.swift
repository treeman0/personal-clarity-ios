import ClarityHubCore
import XCTest
@testable import ClarityHub

private actor AuthorizationCallCounter {
    private(set) var count = 0

    func increment() {
        count += 1
    }
}

private actor OperationCancellationProbe {
    private(set) var wasCancelled = false

    func markCancelled() {
        wasCancelled = true
    }
}

final class HealthKitAuthorizationCoordinatorTests: XCTestCase {
    func testRepeatedAuthorizationSharesOneRequest() async {
        let calls = AuthorizationCallCounter()
        let coordinator = makeCoordinator(
            requestStatus: .shouldRequest,
            requestAuthorization: {
                await calls.increment()
                try await Task.sleep(nanoseconds: 20_000_000)
            }
        )

        async let first = coordinator.authorize()
        async let second = coordinator.authorize()

        let firstOutcome = await first
        let secondOutcome = await second
        let concurrentCallCount = await calls.count
        let repeatedOutcome = await coordinator.authorize()
        let finalCallCount = await calls.count

        XCTAssertEqual(firstOutcome, .ready)
        XCTAssertEqual(secondOutcome, .ready)
        XCTAssertEqual(concurrentCallCount, 1)
        XCTAssertEqual(repeatedOutcome, .ready)
        XCTAssertEqual(finalCallCount, 1)
    }

    func testWeightLoadReturnsEmptyWhenNoSamplesExist() async {
        let coordinator = makeCoordinator(fetchWeights: { _ in [] })

        let outcome = await coordinator.loadWeights(requestAuthorization: false)

        XCTAssertEqual(outcome, .empty)
    }

    func testAuthorizationDenialIsReportedExplicitly() async {
        let coordinator = makeCoordinator(
            requestAuthorization: { throw HealthKitClientError.authorizationDenied }
        )

        let outcome = await coordinator.authorize()

        XCTAssertEqual(outcome, .denied)
    }

    func testWeightQueryTimeoutReturnsWithoutLeavingCallerBlocked() async {
        let probe = OperationCancellationProbe()
        let coordinator = makeCoordinator(
            timeoutNanoseconds: 10_000_000,
            fetchWeights: { _ in
                do {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    return []
                } catch {
                    await probe.markCancelled()
                    throw error
                }
            }
        )

        let outcome = await coordinator.loadWeights(requestAuthorization: false)
        try? await Task.sleep(nanoseconds: 20_000_000)
        let operationWasCancelled = await probe.wasCancelled

        XCTAssertEqual(outcome, .failed(.timedOut))
        XCTAssertTrue(operationWasCancelled)
    }

    func testHealthKitQueryFailureIsReported() async {
        let coordinator = makeCoordinator(
            fetchWeights: { _ in throw HealthKitClientError.authorizationDenied }
        )

        let outcome = await coordinator.loadWeights(requestAuthorization: false)

        XCTAssertEqual(outcome, .denied)
    }

    func testAuthorizationTimeoutReturnsWithoutWaitingForever() async {
        let coordinator = makeCoordinator(
            timeoutNanoseconds: 10_000_000,
            requestAuthorization: {
                try await Task.sleep(nanoseconds: 5_000_000_000)
            }
        )

        let start = Date()
        let outcome = await coordinator.authorize()

        XCTAssertEqual(outcome, .failed(.timedOut))
        XCTAssertLessThan(Date().timeIntervalSince(start), 1)
    }

    func testSuccessfulWeightAndNutritionLoadsReturnData() async {
        let weight = WeightEntry(date: Date(), pounds: 171.4)
        let nutrition = NutritionDay(
            date: Date(),
            calories: 3_000,
            proteinGrams: 180,
            carbohydrateGrams: 340,
            fatGrams: 90,
            source: "Apple Health"
        )
        let coordinator = makeCoordinator(
            fetchWeights: { _ in [weight] },
            fetchNutrition: { _ in nutrition }
        )

        let weightOutcome = await coordinator.loadWeights(requestAuthorization: true)
        let nutritionOutcome = await coordinator.loadTodayNutrition(requestAuthorization: true)

        XCTAssertEqual(weightOutcome, .success([weight]))
        XCTAssertEqual(nutritionOutcome, .success(nutrition))
    }

    func testUnavailableHealthDataSkipsAuthorizationAndQueries() async {
        let coordinator = makeCoordinator(isAvailable: false)

        let authorization = await coordinator.authorize()
        let weights = await coordinator.loadWeights(requestAuthorization: true)
        let nutrition = await coordinator.loadTodayNutrition(requestAuthorization: true)

        XCTAssertEqual(authorization, .unavailable)
        XCTAssertEqual(weights, .unavailable)
        XCTAssertEqual(nutrition, .unavailable)
    }

    private func makeCoordinator(
        isAvailable: Bool = true,
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        requestStatus: HealthKitAuthorizationRequestStatus = .shouldRequest,
        requestAuthorization: @escaping @Sendable () async throws -> Void = {},
        fetchWeights: @escaping @Sendable (Date) async throws -> [WeightEntry] = { _ in [] },
        fetchNutrition: @escaping @Sendable (Calendar) async throws -> NutritionDay? = { _ in nil }
    ) -> HealthKitAuthorizationCoordinator {
        HealthKitAuthorizationCoordinator(
            client: HealthKitClient(
                isAvailable: { isAvailable },
                authorizationRequestStatus: { requestStatus },
                requestAuthorization: requestAuthorization,
                fetchWeights: fetchWeights,
                fetchTodayNutrition: fetchNutrition
            ),
            timeoutNanoseconds: timeoutNanoseconds
        )
    }
}
