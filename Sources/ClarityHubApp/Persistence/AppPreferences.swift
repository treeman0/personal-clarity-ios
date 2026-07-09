import Foundation
import SwiftData

enum AppPreferenceKey: String {
    case goalWeightPounds
    case weighInReminderHour
    case weighInReminderMinute
    case weighInReminderScheduled
    case googleCalendarClientID
    case googleCalendarRedirectURI
}

enum AppPreferences {
    static let defaultGoalWeightPounds = 180.0
    static let defaultReminderHour = 7
    static let defaultReminderMinute = 30
    #if CLARITYHUB_LOCAL
    static let defaultGoogleRedirectURI = "com.treeman0.ClarityHub.Personal:/oauth2redirect/google"
    #else
    static let defaultGoogleRedirectURI = "com.treeman0.ClarityHub:/oauth2redirect/google"
    #endif

    static func string(_ key: AppPreferenceKey, in preferences: [AppPreferenceRecord], default defaultValue: String = "") -> String {
        preferences.first(where: { $0.key == key.rawValue })?.value ?? defaultValue
    }

    static func double(_ key: AppPreferenceKey, in preferences: [AppPreferenceRecord], default defaultValue: Double) -> Double {
        guard
            let value = preferences.first(where: { $0.key == key.rawValue })?.value,
            let number = Double(value)
        else {
            return defaultValue
        }

        return number
    }

    static func integer(_ key: AppPreferenceKey, in preferences: [AppPreferenceRecord], default defaultValue: Int) -> Int {
        guard
            let value = preferences.first(where: { $0.key == key.rawValue })?.value,
            let number = Int(value)
        else {
            return defaultValue
        }

        return number
    }

    static func boolean(_ key: AppPreferenceKey, in preferences: [AppPreferenceRecord], default defaultValue: Bool = false) -> Bool {
        guard let value = preferences.first(where: { $0.key == key.rawValue })?.value else {
            return defaultValue
        }

        return value == "true"
    }

    static func normalizedGoogleRedirectURI(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmed.isEmpty,
            GoogleOAuthConfiguration(clientID: "validation-only", redirectURI: trimmed).callbackScheme != nil
        else {
            return defaultGoogleRedirectURI
        }

        return trimmed
    }

    static func upsert(_ key: AppPreferenceKey, value: String, in context: ModelContext, preferences: [AppPreferenceRecord]) {
        let existing = preferences.filter { $0.key == key.rawValue }
        if existing.isEmpty {
            context.insert(AppPreferenceRecord(key: key.rawValue, value: value))
        } else {
            existing.forEach { $0.value = value }
        }
    }
}
