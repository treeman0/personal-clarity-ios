import Foundation
import SwiftData

enum AppPreferenceKey: String {
    case goalWeightPounds
    case weighInReminderHour
    case weighInReminderMinute
}

enum AppPreferences {
    static let defaultGoalWeightPounds = 180.0
    static let defaultReminderHour = 7
    static let defaultReminderMinute = 30

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

    static func upsert(_ key: AppPreferenceKey, value: String, in context: ModelContext, preferences: [AppPreferenceRecord]) {
        if let existing = preferences.first(where: { $0.key == key.rawValue }) {
            existing.value = value
        } else {
            context.insert(AppPreferenceRecord(key: key.rawValue, value: value))
        }
    }
}

