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
                .environment(\.weighInReminderScheduler, Self.weighInReminderScheduler)
                .environment(\.googleCalendarClient, Self.googleCalendarClient)
                .environment(\.googleCalendarSession, Self.googleCalendarSession)
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
        switch ProcessInfo.processInfo.environment["CLARITYHUB_GOOGLE_CALENDAR_FIXTURE"] {
        case "fail-if-called":
            return GoogleCalendarClient { _ in
                preconditionFailure("Google Calendar API was called while the disconnected UI fixture was active.")
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
        if ProcessInfo.processInfo.environment["CLARITYHUB_GOOGLE_CALENDAR_FIXTURE"] == "connected" {
            return GoogleCalendarSession { configuration in
                configuration.isConfigured ? "fixture-access-token" : nil
            }
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

    private static func fixtureUpcomingCalendarEventsData() -> Data {
        let start = Date().addingTimeInterval(3_600)
        let end = Date().addingTimeInterval(5_400)
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
