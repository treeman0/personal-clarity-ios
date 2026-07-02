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
}
