import XCTest
@testable import ClarityHubCore

final class HabitScheduleTests: XCTestCase {
    func testHabitDueOnConfiguredWeekday() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let monday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 6)))
        let habit = HabitPlan(title: "Weigh in", weekdays: [2], completions: [])

        XCTAssertTrue(HabitSchedule.isDue(habit, on: monday, calendar: calendar))
    }

    func testHabitNotDueOnUnconfiguredWeekday() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let tuesday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 7)))
        let habit = HabitPlan(title: "Lift", weekdays: [2, 4, 6], completions: [])

        XCTAssertFalse(HabitSchedule.isDue(habit, on: tuesday, calendar: calendar))
    }

    func testCompletionStreakCountsBackwardsFromEndDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 8)))
        let completions: Set<DateComponents> = [
            DateComponents(year: 2026, month: 7, day: 8),
            DateComponents(year: 2026, month: 7, day: 7),
            DateComponents(year: 2026, month: 7, day: 6)
        ]

        XCTAssertEqual(HabitSchedule.streakDays(completionDates: completions, endingOn: today, calendar: calendar), 3)
    }

    func testCompletionStreakStopsAtFirstMissingDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 8)))
        let completions: Set<DateComponents> = [
            DateComponents(year: 2026, month: 7, day: 8),
            DateComponents(year: 2026, month: 7, day: 6)
        ]

        XCTAssertEqual(HabitSchedule.streakDays(completionDates: completions, endingOn: today, calendar: calendar), 1)
    }

    func testScheduledStreakSkipsUnscheduledWeekdays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let wednesday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 8)))
        let completions: Set<DateComponents> = [
            DateComponents(year: 2026, month: 7, day: 8),
            DateComponents(year: 2026, month: 7, day: 6)
        ]

        let streak = HabitSchedule.streakCount(
            completionDates: completions,
            scheduledWeekdays: [2, 4, 6],
            endingOn: wednesday,
            calendar: calendar
        )

        XCTAssertEqual(streak, 2)
    }

    func testScheduledStreakStartsFromPreviousDueDayWhenTodayIsNotScheduled() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let thursday = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 9)))
        let completions: Set<DateComponents> = [
            DateComponents(year: 2026, month: 7, day: 8),
            DateComponents(year: 2026, month: 7, day: 6)
        ]

        let streak = HabitSchedule.streakCount(
            completionDates: completions,
            scheduledWeekdays: [2, 4, 6],
            endingOn: thursday,
            calendar: calendar
        )

        XCTAssertEqual(streak, 2)
    }
}
