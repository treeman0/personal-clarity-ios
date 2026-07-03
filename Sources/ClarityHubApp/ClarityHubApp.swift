import ClarityHubCore
import Foundation
import SwiftData
import SwiftUI

@main
struct ClarityHubApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            let environment = ProcessInfo.processInfo.environment
            modelContainer = try ClarityHubModelContainerFactory.make(
                inMemory: Self.shouldUseInMemoryStore(environment: environment),
                configurationName: Self.storeConfigurationName(environment: environment),
                cloudKitSync: Self.cloudKitSync(environment: environment)
            )
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
                .environment(\.weighInReminderScheduler, Self.weighInReminderScheduler)
                .environment(\.googleCalendarClient, Self.googleCalendarClient)
                .environment(\.googleCalendarSession, Self.googleCalendarSession)
        }
    }

    private static func shouldUseInMemoryStore(environment: [String: String]) -> Bool {
        #if DEBUG
        if environment["CLARITYHUB_PERSISTENT_UI_TEST_STORE"] == "1" {
            return false
        }
        #endif

        return environment["XCTestConfigurationFilePath"] != nil
            || environment["CLARITYHUB_IN_MEMORY_STORE"] == "1"
    }

    private static func storeConfigurationName(environment: [String: String]) -> String {
        #if DEBUG
        if let name = environment["CLARITYHUB_STORE_CONFIGURATION_NAME"],
           !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }
        #endif

        return "ClarityHub"
    }

    private static func cloudKitSync(environment: [String: String]) -> ClarityHubModelContainerFactory.CloudKitSync {
        #if DEBUG
        if environment["CLARITYHUB_PERSISTENT_UI_TEST_STORE"] == "1" {
            return .disabled
        }
        #endif

        return .productionPrivate
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
        case "sample":
            return HealthKitWeightStore(
                isAvailable: { true },
                requestAuthorization: {},
                fetchWeights: { _ in Self.fixtureWeightEntries() }
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
        case "sample":
            return NutritionHealthStore(
                requestAuthorization: {},
                fetchTodayNutrition: { calendar in
                    NutritionDay(
                        date: calendar.startOfDay(for: Date()),
                        calories: 3_125,
                        proteinGrams: 186,
                        carbohydrateGrams: 348,
                        fatGrams: 94,
                        source: "Apple Health"
                    )
                }
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
        switch ProcessInfo.processInfo.environment["CLARITYHUB_GOOGLE_CALENDAR_FIXTURE"] {
        case "fail-if-called", "no-token":
            return GoogleCalendarClient { _ in
                preconditionFailure("Google Calendar API was called while a disconnected UI fixture was active.")
            }
        case "connected":
            return GoogleCalendarClient { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!

                if request.httpMethod == "POST" {
                    return (Self.fixtureCreatedCalendarEventData(), response)
                }

                return (Self.fixtureUpcomingCalendarEventsData(), response)
            }
        default:
            break
        }
        #endif

        return GoogleCalendarClient()
    }

    private static var googleCalendarSession: GoogleCalendarSession {
        #if DEBUG
        switch ProcessInfo.processInfo.environment["CLARITYHUB_GOOGLE_CALENDAR_FIXTURE"] {
        case "connected":
            return GoogleCalendarSession { configuration in
                configuration.isConfigured ? "fixture-access-token" : nil
            }
        case "fail-if-called", "no-token":
            return GoogleCalendarSession { _ in nil }
        default:
            break
        }
        #endif

        return GoogleCalendarSession()
    }

    private static var weighInReminderScheduler: WeighInReminderScheduler {
        #if DEBUG
        switch ProcessInfo.processInfo.environment["CLARITYHUB_REMINDER_FIXTURE"] {
        case "authorized":
            return WeighInReminderScheduler(
                authorizationRequester: { _ in true },
                requestScheduler: { _ in },
                requestCanceller: { _ in }
            )
        case "denied":
            return WeighInReminderScheduler(
                authorizationRequester: { _ in false },
                requestScheduler: { _ in },
                requestCanceller: { _ in }
            )
        default:
            break
        }
        #endif

        return WeighInReminderScheduler()
    }

    private static func fixtureWeightEntries() -> [WeightEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let values = [168.0, 168.3, 168.6, 168.8, 169.0, 169.2, 169.5]

        return values.enumerated().compactMap { offset, pounds in
            guard let day = calendar.date(byAdding: .day, value: offset - 6, to: today),
                  let date = calendar.date(byAdding: .hour, value: 7, to: day)
            else {
                return nil
            }
            return WeightEntry(date: date, pounds: pounds)
        }
    }

    private static func fixtureUpcomingCalendarEventsData() -> Data {
        let now = Date()
        let calendar = Calendar.current
        var start = now.addingTimeInterval(3_600)
        if !calendar.isDate(start, inSameDayAs: now) {
            start = now.addingTimeInterval(60)
        }
        if !calendar.isDate(start, inSameDayAs: now) {
            start = now
        }
        let end = start.addingTimeInterval(1_800)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return """
        {
          "items": [
            {
              "id": "fixture-planning-block",
              "summary": "Fixture planning block",
              "start": { "dateTime": "\(formatter.string(from: start))" },
              "end": { "dateTime": "\(formatter.string(from: end))" }
            }
          ]
        }
        """.data(using: .utf8)!
    }

    private static func fixtureCreatedCalendarEventData() -> Data {
        let start = Date().addingTimeInterval(7_200)
        let end = Date().addingTimeInterval(10_800)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return """
        {
          "id": "fixture-created-focus-block",
          "summary": "Focus block",
          "start": { "dateTime": "\(formatter.string(from: start))" },
          "end": { "dateTime": "\(formatter.string(from: end))" }
        }
        """.data(using: .utf8)!
    }
}

#if DEBUG
private enum UITestHealthKitFixtureError: Error {
    case denied
}
#endif
