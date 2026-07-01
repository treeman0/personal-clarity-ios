import UserNotifications
import XCTest
@testable import ClarityHub

final class WeighInReminderSchedulerTests: XCTestCase {
    func testDailyReminderRequestUsesMorningCalendarTrigger() throws {
        let request = WeighInReminderScheduler.dailyRequest(hour: 7, minute: 30)
        let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)

        XCTAssertEqual(request.identifier, WeighInReminderScheduler.dailyNotificationID)
        XCTAssertEqual(request.content.title, "Weigh in")
        XCTAssertEqual(request.content.body, "Step on the scale before the day gets noisy.")
        XCTAssertEqual(trigger.dateComponents.hour, 7)
        XCTAssertEqual(trigger.dateComponents.minute, 30)
        XCTAssertTrue(trigger.repeats)
    }

    func testSnoozeReminderRequestUsesOneShotTimeIntervalTrigger() throws {
        let request = WeighInReminderScheduler.snoozeRequest(minutes: 15)
        let trigger = try XCTUnwrap(request.trigger as? UNTimeIntervalNotificationTrigger)

        XCTAssertEqual(request.identifier, WeighInReminderScheduler.snoozeNotificationID)
        XCTAssertEqual(request.content.title, "Weigh in")
        XCTAssertEqual(request.content.body, "Snoozed for 15 minutes.")
        XCTAssertEqual(trigger.timeInterval, 15 * 60, accuracy: 0.001)
        XCTAssertFalse(trigger.repeats)
    }

    func testSchedulerUsesInjectedAuthorizationAndSchedulingOperations() async throws {
        var authorizationOptions: UNAuthorizationOptions?
        var scheduledRequests: [UNNotificationRequest] = []
        let scheduler = WeighInReminderScheduler(
            authorizationRequester: { options in
                authorizationOptions = options
                return true
            },
            requestScheduler: { request in
                scheduledRequests.append(request)
            },
            requestCanceller: { _ in }
        )

        let authorized = try await scheduler.requestAuthorization()
        try await scheduler.scheduleDailyReminder(hour: 6, minute: 45)
        try await scheduler.snoozeReminder(minutes: 20)

        XCTAssertTrue(authorized)
        XCTAssertTrue(authorizationOptions?.contains(.alert) == true)
        XCTAssertTrue(authorizationOptions?.contains(.badge) == true)
        XCTAssertTrue(authorizationOptions?.contains(.sound) == true)
        XCTAssertEqual(scheduledRequests.map(\.identifier), [
            WeighInReminderScheduler.dailyNotificationID,
            WeighInReminderScheduler.snoozeNotificationID
        ])
    }

    func testSkipSnoozeAndCancelDailyUseExpectedIdentifiers() {
        var cancelledIdentifiers: [[String]] = []
        let scheduler = WeighInReminderScheduler(
            authorizationRequester: { _ in true },
            requestScheduler: { _ in },
            requestCanceller: { identifiers in
                cancelledIdentifiers.append(identifiers)
            }
        )

        scheduler.skipPendingSnooze()
        scheduler.cancelDailyReminder()

        XCTAssertEqual(cancelledIdentifiers, [
            [WeighInReminderScheduler.snoozeNotificationID],
            [WeighInReminderScheduler.dailyNotificationID]
        ])
    }
}
