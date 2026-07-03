enum HealthKitStatusCopy {
    static let weightConnectPrompt = "Connect Apple Health to load smart-scale weight."
    static let weightUnavailable = "Apple Health body-weight data is not available on this device."
    static let weightNoDataOrPermission = "No body-weight samples were available. If you denied Health permission, enable Body Measurements access in the Health app settings."
    static let weightLoadFailed = "Apple Health weight could not be loaded. Check Health permission and try again."
    static let nutritionUnavailable = "Apple Health nutrition data is not available on this device."
    static let nutritionNoDataOrPermission = "Apple Health has no calorie or macro totals for today, or nutrition permission was not granted."
    static let nutritionLoadFailed = "Apple Health nutrition could not be loaded. Check Health permission and try again."

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
