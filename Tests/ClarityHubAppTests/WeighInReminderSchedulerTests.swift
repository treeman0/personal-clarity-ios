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
        XCTAssertEqual(request.content.categoryIdentifier, WeighInReminderNotificationActions.categoryIdentifier)
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
        XCTAssertEqual(request.content.categoryIdentifier, WeighInReminderNotificationActions.categoryIdentifier)
        XCTAssertEqual(trigger.timeInterval, 15 * 60, accuracy: 0.001)
        XCTAssertFalse(trigger.repeats)
    }

    func testReminderNotificationCategoryExposesSnoozeAndSkipActions() {
        let category = WeighInReminderNotificationActions.category()

        XCTAssertEqual(category.identifier, WeighInReminderNotificationActions.categoryIdentifier)
        XCTAssertEqual(category.actions.map(\.identifier), [
            WeighInReminderNotificationActions.snoozeActionIdentifier,
            WeighInReminderNotificationActions.skipSnoozeActionIdentifier
        ])
        XCTAssertEqual(category.actions.map(\.title), [
            "Snooze 15 min",
            "Skip snooze"
        ])
    }

    func testRegisterReminderNotificationCategoryPassesCategoryToRegistrar() {
        var registeredCategories: Set<UNNotificationCategory> = []

        WeighInReminderNotificationActions.registerCategories { categories in
            registeredCategories = categories
        }

        XCTAssertEqual(registeredCategories.map(\.identifier), [
            WeighInReminderNotificationActions.categoryIdentifier
        ])
    }

    func testReminderNotificationActionHandlerRoutesSnoozeAndSkip() async {
        var snoozedMinutes: [Int] = []
        var skipCount = 0
        let handler = WeighInReminderNotificationActions.Handler(
            snooze: { minutes in snoozedMinutes.append(minutes) },
            skipPendingSnooze: { skipCount += 1 }
        )

        let snoozeHandled = await WeighInReminderNotificationActions.handle(
            actionIdentifier: WeighInReminderNotificationActions.snoozeActionIdentifier,
            handler: handler
        )
        let skipHandled = await WeighInReminderNotificationActions.handle(
            actionIdentifier: WeighInReminderNotificationActions.skipSnoozeActionIdentifier,
            handler: handler
        )
        let unknownHandled = await WeighInReminderNotificationActions.handle(
            actionIdentifier: "unknown",
            handler: handler
        )

        XCTAssertTrue(snoozeHandled)
        XCTAssertTrue(skipHandled)
        XCTAssertFalse(unknownHandled)
        XCTAssertEqual(snoozedMinutes, [15])
        XCTAssertEqual(skipCount, 1)
    }

    func testSchedulerUsesInjectedAuthorizationAndSchedulingOperations() async throws {
        var authorizationOptions: UNAuthorizationOptions?
        var scheduledRequests: [UNNotificationRequest] = []
        var cancelledIdentifiers: [[String]] = []
        let scheduler = WeighInReminderScheduler(
            authorizationRequester: { options in
                authorizationOptions = options
                return true
            },
            requestScheduler: { request in
                scheduledRequests.append(request)
            },
            requestCanceller: { identifiers in
                cancelledIdentifiers.append(identifiers)
            }
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
        XCTAssertEqual(cancelledIdentifiers, [
            [WeighInReminderScheduler.dailyNotificationID],
            [WeighInReminderScheduler.snoozeNotificationID]
        ])
    }

    func testAuthorizeAndScheduleDailyReminderSchedulesOnlyWhenAuthorized() async throws {
        var scheduledRequests: [UNNotificationRequest] = []
        var cancelledIdentifiers: [[String]] = []
        let scheduler = WeighInReminderScheduler(
            authorizationRequester: { _ in true },
            requestScheduler: { request in
                scheduledRequests.append(request)
            },
            requestCanceller: { identifiers in
                cancelledIdentifiers.append(identifiers)
            }
        )

        let scheduled = try await scheduler.authorizeAndScheduleDailyReminder(hour: 8, minute: 15)

        XCTAssertTrue(scheduled)
        XCTAssertEqual(scheduledRequests.map(\.identifier), [WeighInReminderScheduler.dailyNotificationID])
        XCTAssertEqual(cancelledIdentifiers, [[WeighInReminderScheduler.dailyNotificationID]])
    }

    func testAuthorizeAndScheduleDailyReminderDoesNotScheduleWhenDenied() async throws {
        var scheduledRequests: [UNNotificationRequest] = []
        let scheduler = WeighInReminderScheduler(
            authorizationRequester: { _ in false },
            requestScheduler: { request in
                scheduledRequests.append(request)
            },
            requestCanceller: { _ in }
        )

        let scheduled = try await scheduler.authorizeAndScheduleDailyReminder(hour: 8, minute: 15)

        XCTAssertFalse(scheduled)
        XCTAssertTrue(scheduledRequests.isEmpty)
    }

    func testSchedulingDailyAndSnoozeCancelExistingPendingRequestsBeforeAddingReplacements() async throws {
        var operations: [String] = []
        let scheduler = WeighInReminderScheduler(
            authorizationRequester: { _ in true },
            requestScheduler: { request in
                operations.append("schedule:\(request.identifier)")
            },
            requestCanceller: { identifiers in
                operations.append("cancel:\(identifiers.joined(separator: ","))")
            }
        )

        try await scheduler.scheduleDailyReminder(hour: 7, minute: 0)
        try await scheduler.snoozeReminder(minutes: 15)

        XCTAssertEqual(operations, [
            "cancel:\(WeighInReminderScheduler.dailyNotificationID)",
            "schedule:\(WeighInReminderScheduler.dailyNotificationID)",
            "cancel:\(WeighInReminderScheduler.snoozeNotificationID)",
            "schedule:\(WeighInReminderScheduler.snoozeNotificationID)"
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
