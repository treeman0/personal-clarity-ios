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

    func testGoalSnapshotStartingValueIsUsedByDefault() {
        let goal = GoalSnapshot(
            title: "Bench press",
            startingValue: 135,
            currentValue: 155,
            targetValue: 185,
            direction: .increase
        )

        let progress = GoalProgressCalculator.progress(for: goal)

        XCTAssertEqual(progress.fractionComplete, 0.4, accuracy: 0.001)
        XCTAssertEqual(progress.remaining, 30, accuracy: 0.001)
        XCTAssertFalse(progress.isComplete)
    }

    func testDecreaseGoalProgressUsesSnapshotStartingValue() {
        let goal = GoalSnapshot(
            title: "Inbox",
            startingValue: 50,
            currentValue: 20,
            targetValue: 0,
            direction: .decrease
        )

        let progress = GoalProgressCalculator.progress(for: goal)

        XCTAssertEqual(progress.fractionComplete, 0.6, accuracy: 0.001)
        XCTAssertEqual(progress.remaining, -20, accuracy: 0.001)
        XCTAssertFalse(progress.isComplete)
    }

    func testMaintainGoalIsCompleteWhenCurrentValueMatchesTarget() {
        let goal = GoalSnapshot(
            title: "Sleep",
            startingValue: 8,
            currentValue: 8,
            targetValue: 8,
            direction: .maintain
        )

        let progress = GoalProgressCalculator.progress(for: goal)

        XCTAssertEqual(progress.fractionComplete, 1, accuracy: 0.001)
        XCTAssertEqual(progress.remaining, 0, accuracy: 0.001)
        XCTAssertTrue(progress.isComplete)
    }

    func testMaintainGoalDetectsDriftWhenStartingAtTarget() {
        let goal = GoalSnapshot(
            title: "Sleep",
            startingValue: 8,
            currentValue: 6.5,
            targetValue: 8,
            direction: .maintain
        )

        let progress = GoalProgressCalculator.progress(for: goal)

        XCTAssertEqual(progress.fractionComplete, 0, accuracy: 0.001)
        XCTAssertEqual(progress.remaining, 1.5, accuracy: 0.001)
        XCTAssertFalse(progress.isComplete)
    }
}
