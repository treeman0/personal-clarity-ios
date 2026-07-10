import SwiftUI

private struct HealthKitAuthorizationCoordinatorKey: EnvironmentKey {
    static let defaultValue = HealthKitAuthorizationCoordinator()
}

private struct WeighInReminderSchedulerKey: EnvironmentKey {
    static let defaultValue = WeighInReminderScheduler()
}

private struct GoogleCalendarClientKey: EnvironmentKey {
    static let defaultValue = GoogleCalendarClient()
}

private struct GoogleCalendarSessionKey: EnvironmentKey {
    static let defaultValue = GoogleCalendarSession()
}

extension EnvironmentValues {
    var healthKitAuthorizationCoordinator: HealthKitAuthorizationCoordinator {
        get { self[HealthKitAuthorizationCoordinatorKey.self] }
        set { self[HealthKitAuthorizationCoordinatorKey.self] = newValue }
    }

    var weighInReminderScheduler: WeighInReminderScheduler {
        get { self[WeighInReminderSchedulerKey.self] }
        set { self[WeighInReminderSchedulerKey.self] = newValue }
    }

    var googleCalendarClient: GoogleCalendarClient {
        get { self[GoogleCalendarClientKey.self] }
        set { self[GoogleCalendarClientKey.self] = newValue }
    }

    var googleCalendarSession: GoogleCalendarSession {
        get { self[GoogleCalendarSessionKey.self] }
        set { self[GoogleCalendarSessionKey.self] = newValue }
    }
}
