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
}

