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
                .environment(\.healthKitWeightStore, HealthKitWeightStore())
                .environment(\.nutritionHealthStore, NutritionHealthStore())
                .environment(\.weighInReminderScheduler, WeighInReminderScheduler())
                .environment(\.googleCalendarClient, GoogleCalendarClient())
        }
    }

    private static var shouldUseInMemoryStore: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil
            || environment["CLARITYHUB_IN_MEMORY_STORE"] == "1"
    }
}
