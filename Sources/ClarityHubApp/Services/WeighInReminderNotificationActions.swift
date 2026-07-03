import UserNotifications

enum WeighInReminderNotificationActions {
    struct Handler {
        var snooze: (Int) async throws -> Void
        var skipPendingSnooze: () -> Void

        static let live = Handler(
            snooze: { minutes in
                try await WeighInReminderScheduler().snoozeReminder(minutes: minutes)
            },
            skipPendingSnooze: {
                WeighInReminderScheduler().skipPendingSnooze()
            }
        )
    }

    static let dailyCategoryIdentifier = "clarityhub.weigh-in.daily-actions"
    static let snoozeCategoryIdentifier = "clarityhub.weigh-in.snooze-actions"
    static let snoozeActionIdentifier = "clarityhub.weigh-in.action.snooze"
    static let skipSnoozeActionIdentifier = "clarityhub.weigh-in.action.skip-snooze"

    static func dailyCategory() -> UNNotificationCategory {
        UNNotificationCategory(
            identifier: dailyCategoryIdentifier,
            actions: [
                UNNotificationAction(
                    identifier: snoozeActionIdentifier,
                    title: "Snooze 15 min",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )
    }

    static func snoozeCategory() -> UNNotificationCategory {
        UNNotificationCategory(
            identifier: snoozeCategoryIdentifier,
            actions: [
                UNNotificationAction(
                    identifier: skipSnoozeActionIdentifier,
                    title: "Skip snooze",
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )
    }

    static func registerCategories(_ registrar: (Set<UNNotificationCategory>) -> Void) {
        registrar([dailyCategory(), snoozeCategory()])
    }

    @discardableResult
    static func handle(
        actionIdentifier: String,
        handler: Handler = .live
    ) async -> Bool {
        switch actionIdentifier {
        case snoozeActionIdentifier:
            try? await handler.snooze(15)
            return true
        case skipSnoozeActionIdentifier:
            handler.skipPendingSnooze()
            return true
        default:
            return false
        }
    }
}
