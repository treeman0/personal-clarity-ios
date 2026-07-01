import XCTest
@testable import ClarityHubCore

final class WeightTrendCalculatorTests: XCTestCase {
    func testTrendCalculatesLatestAverageGoalDeltaAndStreak() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 8)))
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today))
        let twoDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -2, to: today))

        let entries = [
            WeightEntry(date: twoDaysAgo, pounds: 165),
            WeightEntry(date: yesterday, pounds: 166),
            WeightEntry(date: today, pounds: 167)
        ]

        let trend = WeightTrendCalculator.trend(entries: entries, goalWeight: 180, today: today, calendar: calendar)

        XCTAssertEqual(trend.latestWeight, 167)
        XCTAssertEqual(trend.movingAverage ?? 0, 166, accuracy: 0.001)
        XCTAssertEqual(trend.deltaToGoal, 13)
        XCTAssertEqual(trend.weighInStreakDays, 3)
    }

    func testMovingAverageSeriesUsesRollingWindow() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 1)))
        let entries = try (0..<4).map { offset in
            WeightEntry(
                date: try XCTUnwrap(calendar.date(byAdding: .day, value: offset, to: start)),
                pounds: Double(160 + offset)
            )
        }

        let series = WeightTrendCalculator.movingAverageSeries(entries: entries, window: 3)

        XCTAssertEqual(series.map(\.pounds), [160, 160.5, 161, 162])
    }
}
