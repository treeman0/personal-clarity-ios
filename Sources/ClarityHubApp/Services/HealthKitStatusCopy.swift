enum HealthKitStatusCopy {
    static let weightConnectPrompt = "Connect Apple Health to load smart-scale weight."
    static let weightUnavailable = "Apple Health body-weight data is not available on this device."
    static let weightNoDataOrPermission = "No body-weight samples were available. If you denied Health permission, enable Body Measurements access in the Health app settings."
    static let weightDenied = "Body-weight access was denied. Enable Body Measurements access in the Health app settings, then try again."
    static let weightLoadFailed = "Apple Health weight could not be loaded. Check Health permission and try again."
    static let weightTimedOut = "Apple Health did not respond in time. The app stopped waiting; try again when Health is available."
    static let nutritionUnavailable = "Apple Health nutrition data is not available on this device."
    static let nutritionNoDataOrPermission = "Apple Health has no calorie or macro totals for today, or nutrition permission was not granted."
    static let nutritionDenied = "Nutrition access was denied. Enable Nutrition access in the Health app settings, then try again."
    static let nutritionLoadFailed = "Apple Health nutrition could not be loaded. Check Health permission and try again."
    static let nutritionTimedOut = "Apple Health did not respond in time. The app stopped waiting; try nutrition again later."

    static func setupAuthorizationMessage(
        healthOutcome: HealthKitAuthorizationOutcome,
        reminderScheduled: Bool
    ) -> String {
        let healthMessage: String
        switch healthOutcome {
        case .ready:
            healthMessage = "Apple Health access request completed."
        case .denied:
            healthMessage = "Apple Health access was denied. Review Body Measurements and Nutrition in Health settings."
        case .unavailable:
            healthMessage = "Apple Health data is unavailable on this device."
        case .failed(.timedOut):
            healthMessage = "Apple Health did not respond in time; ClarityHub stopped waiting."
        case .failed(.healthKit):
            healthMessage = "Apple Health access could not be completed."
        }
        let reminderMessage = reminderScheduled
            ? "Morning reminder scheduled."
            : "Notification permission still needs attention."
        return "\(healthMessage) \(reminderMessage)"
    }

    static func setupAuthorizationMessage(reminderScheduled: Bool) -> String {
        setupAuthorizationMessage(
            bodyAuthorized: true,
            nutritionAuthorized: true,
            reminderScheduled: reminderScheduled
        )
    }

    static func setupAuthorizationMessage(
        bodyAvailable: Bool = true,
        nutritionAvailable: Bool = true,
        bodyAuthorized: Bool,
        nutritionAuthorized: Bool,
        reminderScheduled: Bool
    ) -> String {
        let attentionItems = [
            bodyAvailable ? (bodyAuthorized ? nil : "body-weight Health permission") : "body-weight Health data unavailable",
            nutritionAvailable ? (nutritionAuthorized ? nil : "nutrition Health permission") : "nutrition Health data unavailable",
            reminderScheduled ? nil : "notification permission"
        ].compactMap { $0 }

        if attentionItems.isEmpty {
            return "Health permissions requested and reminder scheduled. If Health data stays empty, confirm access in Health settings."
        }
        return "Setup access requested. Needs attention: \(attentionItems.joined(separator: ", "))."
    }
}
