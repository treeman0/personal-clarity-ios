import XCTest
@testable import ClarityHubCore

final class NutritionImportParserTests: XCTestCase {
    func testParsesDailyTotalsFromPlainText() throws {
        let result = try XCTUnwrap(NutritionImportParser.parseDailyTotals("Calories 2840 Protein 172 Carbs 286 Fat 92"))

        XCTAssertEqual(result.calories, 2840, accuracy: 0.001)
        XCTAssertEqual(result.proteinGrams, 172, accuracy: 0.001)
        XCTAssertEqual(result.carbohydrateGrams, 286, accuracy: 0.001)
        XCTAssertEqual(result.fatGrams, 92, accuracy: 0.001)
        XCTAssertEqual(result.source, "Manual import")
    }

    func testReturnsNilWithoutCalories() {
        XCTAssertNil(NutritionImportParser.parseDailyTotals("Protein 172 Carbs 286 Fat 92"))
    }

    func testPreservesSelectedDateAndSource() throws {
        let calendar = Calendar(identifier: .gregorian)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 1)))

        let result = try XCTUnwrap(NutritionImportParser.parseDailyTotals(
            "kcal 3100 p 180 c 340 f 95",
            date: date,
            source: "Cal AI import"
        ))

        XCTAssertEqual(result.date, date)
        XCTAssertEqual(result.source, "Cal AI import")
    }

    func testParsesCommaFormattedTotals() throws {
        let result = try XCTUnwrap(NutritionImportParser.parseDailyTotals(
            "Calories: 2,840 kcal\nProtein: 172g\nCarbs: 1,286g\nFat: 92g"
        ))

        XCTAssertEqual(result.calories, 2840, accuracy: 0.001)
        XCTAssertEqual(result.proteinGrams, 172, accuracy: 0.001)
        XCTAssertEqual(result.carbohydrateGrams, 1286, accuracy: 0.001)
        XCTAssertEqual(result.fatGrams, 92, accuracy: 0.001)
    }
}
