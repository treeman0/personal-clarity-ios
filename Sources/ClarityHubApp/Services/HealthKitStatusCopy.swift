enum HealthKitStatusCopy {
    static let weightConnectPrompt = "Connect Apple Health to load smart-scale weight."
    static let weightNoDataOrPermission = "No body-weight samples were available. If you denied Health permission, enable Body Measurements access in the Health app settings."
    static let weightLoadFailed = "Apple Health weight could not be loaded. Check Health permission and try again."
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
        bodyAuthorized: Bool,
        nutritionAuthorized: Bool,
        reminderScheduled: Bool
    ) -> String {
        let attentionItems = [
            bodyAuthorized ? nil : "body-weight Health permission",
            nutritionAuthorized ? nil : "nutrition Health permission",
            reminderScheduled ? nil : "notification permission"
        ].compactMap { $0 }

        if attentionItems.isEmpty {
            return "Health permissions requested and reminder scheduled. If Health data stays empty, confirm access in Health settings."
        }
        return "Setup access requested. Needs attention: \(attentionItems.joined(separator: ", "))."
    }
}
