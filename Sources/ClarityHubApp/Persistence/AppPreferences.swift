import Foundation
import SwiftData

enum AppPreferenceKey: String {
    case goalWeightPounds
    case weighInReminderHour
    case weighInReminderMinute
    case googleCalendarClientID
    case googleCalendarRedirectURI
}

enum AppPreferences {
    static let defaultGoalWeightPounds = 180.0
    static let defaultReminderHour = 7
    static let defaultReminderMinute = 30
    static let defaultGoogleRedirectURI = "com.treeman0.ClarityHub:/oauth2redirect/google"

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

    static func normalizedGoogleRedirectURI(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultGoogleRedirectURI : trimmed
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
