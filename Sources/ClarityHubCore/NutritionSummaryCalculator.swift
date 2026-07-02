import Foundation

public struct NutritionSummary: Equatable, Sendable {
    public let dayCount: Int
    public let averageCalories: Double
    public let averageProteinGrams: Double
    public let averageCarbohydrateGrams: Double
    public let averageFatGrams: Double

    public init(
        dayCount: Int,
        averageCalories: Double,
        averageProteinGrams: Double,
        averageCarbohydrateGrams: Double,
        averageFatGrams: Double
    ) {
        self.dayCount = dayCount
        self.averageCalories = averageCalories
        self.averageProteinGrams = averageProteinGrams
        self.averageCarbohydrateGrams = averageCarbohydrateGrams
        self.averageFatGrams = averageFatGrams
    }
}

public enum NutritionSummaryCalculator {
    public static func recentAverage(_ days: [NutritionDay], limit: Int = 7) -> NutritionSummary {
        let recentDays = days
            .sorted { $0.date > $1.date }
            .prefix(max(0, limit))

        guard !recentDays.isEmpty else {
            return NutritionSummary(
                dayCount: 0,
                averageCalories: 0,
                averageProteinGrams: 0,
                averageCarbohydrateGrams: 0,
                averageFatGrams: 0
            )
        }

        let count = Double(recentDays.count)
        return NutritionSummary(
            dayCount: recentDays.count,
            averageCalories: recentDays.reduce(0) { $0 + $1.calories } / count,
            averageProteinGrams: recentDays.reduce(0) { $0 + $1.proteinGrams } / count,
            averageCarbohydrateGrams: recentDays.reduce(0) { $0 + $1.carbohydrateGrams } / count,
            averageFatGrams: recentDays.reduce(0) { $0 + $1.fatGrams } / count
        )
    }
}
