import Foundation
import UserNotifications

struct WeighInReminderScheduler {
    private let notificationID = "clarityhub.weigh-in.morning"

    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Weigh in"
        content.body = "Step on the scale before the day gets noisy."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}

