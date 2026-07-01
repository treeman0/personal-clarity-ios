import XCTest
@testable import ClarityHubCore

final class GoalProgressCalculatorTests: XCTestCase {
    func testIncreaseGoalProgressUsesStartingValue() {
        let goal = GoalSnapshot(title: "Gain weight", currentValue: 170, targetValue: 180, direction: .increase)

        let progress = GoalProgressCalculator.progress(for: goal, startingValue: 160)

        XCTAssertEqual(progress.fractionComplete, 0.5, accuracy: 0.001)
        XCTAssertEqual(progress.remaining, 10, accuracy: 0.001)
        XCTAssertFalse(progress.isComplete)
    }

    func testDecreaseGoalCompletion() {
        let goal = GoalSnapshot(title: "Cut", currentValue: 190, targetValue: 190, direction: .decrease)

        let progress = GoalProgressCalculator.progress(for: goal, startingValue: 210)

        XCTAssertEqual(progress.fractionComplete, 1, accuracy: 0.001)
        XCTAssertTrue(progress.isComplete)
    }
}

