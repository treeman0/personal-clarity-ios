import Foundation

public enum NutritionImportParser {
    public static func parseDailyTotals(
        _ text: String,
        date: Date = Date(),
        source: String = "Manual import"
    ) -> NutritionDay? {
        let normalized = text.lowercased()
        guard let calories = value(afterAnyOf: ["calories", "cal", "kcal"], in: normalized) else {
            return nil
        }

        return NutritionDay(
            date: date,
            calories: calories,
            proteinGrams: value(afterAnyOf: ["protein", "p"], in: normalized) ?? 0,
            carbohydrateGrams: value(afterAnyOf: ["carbs", "carbohydrates", "c"], in: normalized) ?? 0,
            fatGrams: value(afterAnyOf: ["fat", "f"], in: normalized) ?? 0,
            source: source
        )
    }

    private static func value(afterAnyOf labels: [String], in text: String) -> Double? {
        for label in labels {
            if let value = value(after: label, in: text) {
                return value
            }
        }
        return nil
    }

    private static func value(after label: String, in text: String) -> Double? {
        let pattern = "\(NSRegularExpression.escapedPattern(for: label))\\s*[:=-]?\\s*(\\d+(?:\\.\\d+)?)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard
            let match = regex.firstMatch(in: text, range: range),
            match.numberOfRanges > 1,
            let valueRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }
        return Double(text[valueRange])
    }
}
