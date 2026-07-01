import Foundation
import SwiftData
import SwiftUI

@main
struct ClarityHubApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ClarityHubModelContainerFactory.make(inMemory: Self.isRunningTests)
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

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
