import Foundation

public enum WeightTrendCalculator {
    public static func trend(
        entries: [WeightEntry],
        goalWeight: Double?,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> WeightTrend {
        let sorted = entries.sorted { $0.date < $1.date }
        let latest = sorted.last
        let recent = sorted.suffix(7)
        let movingAverage = recent.isEmpty ? nil : recent.map(\.pounds).reduce(0, +) / Double(recent.count)
        let delta = goalWeight.flatMap { goal in latest.map { goal - $0.pounds } }
        let sevenDayChange = changeOverSevenDays(entries: sorted, today: today, calendar: calendar)

        return WeightTrend(
            latestWeight: latest?.pounds,
            movingAverage: movingAverage,
            deltaToGoal: delta,
            sevenDayChange: sevenDayChange,
            weighInStreakDays: streakDays(entries: sorted, today: today, calendar: calendar)
        )
    }

    public static func movingAverageSeries(entries: [WeightEntry], window: Int = 7) -> [WeightMovingAveragePoint] {
        guard window > 0 else { return [] }
        let sorted = entries.sorted { $0.date < $1.date }

        return sorted.indices.map { index in
            let start = max(sorted.startIndex, index - window + 1)
            let values = sorted[start...index].map(\.pounds)
            let average = values.reduce(0, +) / Double(values.count)
            return WeightMovingAveragePoint(date: sorted[index].date, pounds: average)
        }
    }

    private static func changeOverSevenDays(
        entries: [WeightEntry],
        today: Date,
        calendar: Calendar
    ) -> Double? {
        guard let latest = entries.last else { return nil }
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) else { return nil }
        let baseline = entries.last { $0.date <= sevenDaysAgo } ?? entries.first
        return baseline.map { latest.pounds - $0.pounds }
    }

    private static func streakDays(entries: [WeightEntry], today: Date, calendar: Calendar) -> Int {
        let daysWithWeight = Set(entries.map { calendar.startOfDay(for: $0.date) })
        var cursor = calendar.startOfDay(for: today)
        var streak = 0

        while daysWithWeight.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return streak
    }
}
