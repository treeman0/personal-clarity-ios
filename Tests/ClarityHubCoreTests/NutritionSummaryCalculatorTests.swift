import XCTest
@testable import ClarityHubCore

final class NutritionSummaryCalculatorTests: XCTestCase {
    func testRecentAverageSummarizesCaloriesAndMacros() {
        let calendar = Calendar(identifier: .gregorian)
        let days = [
            NutritionDay(
                date: calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!,
                calories: 2_800,
                proteinGrams: 170,
                carbohydrateGrams: 300,
                fatGrams: 80,
                source: "Manual import"
            ),
            NutritionDay(
                date: calendar.date(from: DateComponents(year: 2026, month: 7, day: 2))!,
                calories: 3_000,
                proteinGrams: 190,
                carbohydrateGrams: 320,
                fatGrams: 90,
                source: "Cal AI import"
            )
        ]

        let summary = NutritionSummaryCalculator.recentAverage(days, limit: 7)

        XCTAssertEqual(summary.dayCount, 2)
        XCTAssertEqual(summary.averageCalories, 2_900, accuracy: 0.001)
        XCTAssertEqual(summary.averageProteinGrams, 180, accuracy: 0.001)
        XCTAssertEqual(summary.averageCarbohydrateGrams, 310, accuracy: 0.001)
        XCTAssertEqual(summary.averageFatGrams, 85, accuracy: 0.001)
    }

    func testRecentAverageUsesMostRecentDaysOnly() {
        let calendar = Calendar(identifier: .gregorian)
        let days = [
            NutritionDay(date: calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!, calories: 1_000, proteinGrams: 10, carbohydrateGrams: 20, fatGrams: 30, source: "Old"),
            NutritionDay(date: calendar.date(from: DateComponents(year: 2026, month: 7, day: 2))!, calories: 2_000, proteinGrams: 20, carbohydrateGrams: 30, fatGrams: 40, source: "Recent"),
            NutritionDay(date: calendar.date(from: DateComponents(year: 2026, month: 7, day: 3))!, calories: 3_000, proteinGrams: 30, carbohydrateGrams: 40, fatGrams: 50, source: "Recent")
        ]

        let summary = NutritionSummaryCalculator.recentAverage(days, limit: 2)

        XCTAssertEqual(summary.dayCount, 2)
        XCTAssertEqual(summary.averageCalories, 2_500, accuracy: 0.001)
    }

    func testRecentAverageIsEmptyWhenNoDaysExist() {
        let summary = NutritionSummaryCalculator.recentAverage([])

        XCTAssertEqual(summary.dayCount, 0)
        XCTAssertEqual(summary.averageCalories, 0, accuracy: 0.001)
    }
}
