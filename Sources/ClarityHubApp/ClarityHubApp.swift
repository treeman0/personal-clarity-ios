import Foundation
import SwiftData
import SwiftUI

@main
struct ClarityHubApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ClarityHubModelContainerFactory.make(inMemory: Self.shouldUseInMemoryStore)
            #if DEBUG
            try UITestFixtureSeeder.seedIfRequested(in: modelContainer)
            #endif
        } catch {
            fatalError("Unable to create ClarityHub model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .modelContainer(modelContainer)
                .environment(\.healthKitWeightStore, Self.healthKitWeightStore)
                .environment(\.nutritionHealthStore, Self.nutritionHealthStore)
                .environment(\.weighInReminderScheduler, WeighInReminderScheduler())
                .environment(\.googleCalendarClient, Self.googleCalendarClient)
        }
    }

    private static var shouldUseInMemoryStore: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil
            || environment["CLARITYHUB_IN_MEMORY_STORE"] == "1"
    }

    private static var healthKitWeightStore: HealthKitWeightStore {
        #if DEBUG
        switch ProcessInfo.processInfo.environment["CLARITYHUB_HEALTHKIT_FIXTURE"] {
        case "empty":
            return HealthKitWeightStore(
                isAvailable: { true },
                requestAuthorization: {},
                fetchWeights: { _ in [] }
            )
        case "denied":
            return HealthKitWeightStore(
                isAvailable: { true },
                requestAuthorization: { throw UITestHealthKitFixtureError.denied },
                fetchWeights: { _ in throw UITestHealthKitFixtureError.denied }
            )
        default:
            break
        }
        #endif

        return HealthKitWeightStore()
    }

    private static var nutritionHealthStore: NutritionHealthStore {
        #if DEBUG
        switch ProcessInfo.processInfo.environment["CLARITYHUB_HEALTHKIT_FIXTURE"] {
        case "empty":
            return NutritionHealthStore(
                requestAuthorization: {},
                fetchTodayNutrition: { _ in nil }
            )
        case "denied":
            return NutritionHealthStore(
                requestAuthorization: { throw UITestHealthKitFixtureError.denied },
                fetchTodayNutrition: { _ in throw UITestHealthKitFixtureError.denied }
            )
        default:
            break
        }
        #endif

        return NutritionHealthStore()
    }

    private static var googleCalendarClient: GoogleCalendarClient {
        #if DEBUG
        if ProcessInfo.processInfo.environment["CLARITYHUB_GOOGLE_CALENDAR_FIXTURE"] == "fail-if-called" {
            return GoogleCalendarClient { _ in
                preconditionFailure("Google Calendar API was called while the disconnected UI fixture was active.")
            }
        }
        #endif

        return GoogleCalendarClient()
    }
}

#if DEBUG
private enum UITestHealthKitFixtureError: Error {
    case denied
}
#endif
