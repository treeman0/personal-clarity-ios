import Foundation
import UserNotifications

struct WeighInReminderScheduler {
    typealias AuthorizationRequester = (UNAuthorizationOptions) async throws -> Bool
    typealias RequestScheduler = (UNNotificationRequest) async throws -> Void
    typealias RequestCanceller = ([String]) -> Void

    static let dailyNotificationID = "clarityhub.weigh-in.morning"
    static let snoozeNotificationID = "clarityhub.weigh-in.snooze"

    private let authorizationRequester: AuthorizationRequester
    private let requestScheduler: RequestScheduler
    private let requestCanceller: RequestCanceller

    init(
        authorizationRequester: @escaping AuthorizationRequester = { options in
            try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        },
        requestScheduler: @escaping RequestScheduler = { request in
            try await UNUserNotificationCenter.current().add(request)
        },
        requestCanceller: @escaping RequestCanceller = { identifiers in
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    ) {
        self.authorizationRequester = authorizationRequester
        self.requestScheduler = requestScheduler
        self.requestCanceller = requestCanceller
    }

    func requestAuthorization() async throws -> Bool {
        try await authorizationRequester([.alert, .badge, .sound])
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        requestCanceller([Self.dailyNotificationID])
        try await requestScheduler(Self.dailyRequest(hour: hour, minute: minute))
    }

    func authorizeAndScheduleDailyReminder(hour: Int, minute: Int) async throws -> Bool {
        let authorized = try await requestAuthorization()
        guard authorized else { return false }
        try await scheduleDailyReminder(hour: hour, minute: minute)
        return true
    }

    func snoozeReminder(minutes: Int = 15) async throws {
        requestCanceller([Self.snoozeNotificationID])
        try await requestScheduler(Self.snoozeRequest(minutes: minutes))
    }

    func skipPendingSnooze() {
        requestCanceller([Self.snoozeNotificationID])
    }

    func cancelDailyReminder() {
        requestCanceller([Self.dailyNotificationID])
    }

    static func dailyRequest(hour: Int, minute: Int) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Weigh in"
        content.body = "Step on the scale before the day gets noisy."
        content.sound = .default
        content.categoryIdentifier = WeighInReminderNotificationActions.dailyCategoryIdentifier

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        return UNNotificationRequest(identifier: dailyNotificationID, content: content, trigger: trigger)
    }

    static func snoozeRequest(minutes: Int = 15) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Weigh in"
        content.body = "Snoozed for \(minutes) minutes."
        content.sound = .default
        content.categoryIdentifier = WeighInReminderNotificationActions.snoozeCategoryIdentifier

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        return UNNotificationRequest(identifier: snoozeNotificationID, content: content, trigger: trigger)
    }
}
