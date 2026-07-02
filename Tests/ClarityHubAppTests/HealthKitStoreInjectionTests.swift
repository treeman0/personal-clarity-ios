import ClarityHubCore
import XCTest
@testable import ClarityHub

private enum HealthKitStoreInjectionError: Error {
    case denied
}

final class HealthKitStoreInjectionTests: XCTestCase {
    func testWeightStoreCanReturnInjectedEmptySamples() async throws {
        let store = HealthKitWeightStore(
            isAvailable: { true },
            requestAuthorization: {},
            fetchWeights: { _ in [] }
        )

        XCTAssertTrue(store.isAvailable)
        try await store.requestAuthorization()
        let entries = try await store.fetchWeights(since: Date())
        XCTAssertTrue(entries.isEmpty)
    }

    func testWeightStoreCanReturnInjectedAuthorizationFailure() async {
        let store = HealthKitWeightStore(
            isAvailable: { true },
            requestAuthorization: { throw HealthKitStoreInjectionError.denied },
            fetchWeights: { _ in throw HealthKitStoreInjectionError.denied }
        )

        do {
            try await store.requestAuthorization()
            XCTFail("Expected injected authorization failure.")
        } catch HealthKitStoreInjectionError.denied {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testNutritionStoreCanReturnInjectedEmptyDay() async throws {
        let store = NutritionHealthStore(
            requestAuthorization: {},
            fetchTodayNutrition: { _ in nil }
        )

        try await store.requestAuthorization()
        let day = try await store.fetchTodayNutrition()
        XCTAssertNil(day)
    }

    func testNutritionStoreCanReturnInjectedAuthorizationFailure() async {
        let store = NutritionHealthStore(
            requestAuthorization: { throw HealthKitStoreInjectionError.denied },
            fetchTodayNutrition: { _ in throw HealthKitStoreInjectionError.denied }
        )

        do {
            try await store.requestAuthorization()
            XCTFail("Expected injected authorization failure.")
        } catch HealthKitStoreInjectionError.denied {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
