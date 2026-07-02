import XCTest
@testable import ClarityHubCore

final class ReviewFocusPlannerTests: XCTestCase {
    func testNextActionTrimsFocusAndSetsTomorrowDueDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let reviewDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 8, hour: 20))!

        let action = ReviewFocusPlanner.nextAction(
            from: "  Plan training meals  ",
            reviewDate: reviewDate,
            calendar: calendar
        )

        XCTAssertEqual(action?.title, "Plan training meals")
        XCTAssertEqual(action?.priority, 3)
        XCTAssertEqual(action?.status, .open)
        XCTAssertEqual(action?.dueDate, calendar.date(from: DateComponents(year: 2026, month: 7, day: 9)))
    }

    func testNextActionReturnsNilForBlankFocus() {
        XCTAssertNil(ReviewFocusPlanner.nextAction(from: "   "))
    }

    func testMatchingOpenActionDedupesByTitleAndDueDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let dueMorning = calendar.date(from: DateComponents(year: 2026, month: 7, day: 9, hour: 8))!
        let dueEvening = calendar.date(from: DateComponents(year: 2026, month: 7, day: 9, hour: 20))!
        let action = TaskItem(title: "Plan training meals", status: .open, dueDate: dueMorning, priority: 3)
        let existing = TaskItem(title: "Plan training meals", status: .open, dueDate: dueEvening, priority: 1)

        XCTAssertTrue(ReviewFocusPlanner.containsMatchingOpenAction([existing], action: action, calendar: calendar))
    }

    func testCompletedOrDifferentDayActionsDoNotDedupeReviewFocus() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let dueDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 9))!
        let nextDay = calendar.date(from: DateComponents(year: 2026, month: 7, day: 10))!
        let action = TaskItem(title: "Plan training meals", status: .open, dueDate: dueDate, priority: 3)
        let completed = TaskItem(title: "Plan training meals", status: .done, dueDate: dueDate, priority: 3)
        let differentDay = TaskItem(title: "Plan training meals", status: .open, dueDate: nextDay, priority: 3)

        XCTAssertFalse(ReviewFocusPlanner.containsMatchingOpenAction([completed, differentDay], action: action, calendar: calendar))
    }
}
