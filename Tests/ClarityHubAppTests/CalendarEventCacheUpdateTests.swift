import Foundation
import XCTest
@testable import ClarityHub

final class CalendarEventCacheUpdateTests: XCTestCase {
    func testClearRemovesEventsAndCanPreserveExistingStatus() {
        let update = CalendarEventCacheUpdate.clear()

        XCTAssertTrue(update.events.isEmpty)
        XCTAssertNil(update.statusMessage)
    }

    func testClearRemovesEventsAndCarriesStatusWhenProvided() {
        let update = CalendarEventCacheUpdate.clear(statusMessage: "Connect Google Calendar before refreshing.")

        XCTAssertTrue(update.events.isEmpty)
        XCTAssertEqual(update.statusMessage, "Connect Google Calendar before refreshing.")
    }

    func testLoadedUsesLoadedStatusForVisibleEvents() throws {
        let start = try XCTUnwrap(Self.date("2026-07-02T09:00:00Z"))
        let end = try XCTUnwrap(Self.date("2026-07-02T10:00:00Z"))
        let event = CalendarEvent(
            id: "focus",
            title: "Focus block",
            startDate: start,
            endDate: end,
            calendarName: "Google Calendar"
        )

        let update = CalendarEventCacheUpdate.loaded(
            [event],
            emptyStatusMessage: "No remaining Google Calendar blocks today.",
            loadedStatusMessage: "Loaded 1 calendar blocks."
        )

        XCTAssertEqual(update.events, [event])
        XCTAssertEqual(update.statusMessage, "Loaded 1 calendar blocks.")
    }

    func testLoadedUsesEmptyStatusWhenNoEventsRemain() {
        let update = CalendarEventCacheUpdate.loaded(
            [],
            emptyStatusMessage: "No upcoming Google Calendar events found.",
            loadedStatusMessage: "Loaded 0 events."
        )

        XCTAssertTrue(update.events.isEmpty)
        XCTAssertEqual(update.statusMessage, "No upcoming Google Calendar events found.")
    }

    private static func date(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
