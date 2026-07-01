import Foundation

public enum HabitSchedule {
    public static func isDue(_ habit: HabitPlan, on date: Date, calendar: Calendar = .current) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return habit.weekdays.contains(weekday)
    }

    public static func isComplete(_ habit: HabitPlan, on date: Date, calendar: Calendar = .current) -> Bool {
        let targetDay = DayKey(date: date, calendar: calendar)
        return habit.completions.map(DayKey.init).contains(targetDay)
    }

    public static func streakDays(
        completionDates: Set<DateComponents>,
        endingOn date: Date,
        calendar: Calendar = .current
    ) -> Int {
        var streak = 0
        var cursor = calendar.startOfDay(for: date)
        let completedDays = Set(completionDates.map(DayKey.init))

        while true {
            guard completedDays.contains(DayKey(date: cursor, calendar: calendar)) else { break }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return streak
    }

    private struct DayKey: Hashable {
        let year: Int
        let month: Int
        let day: Int

        init(_ components: DateComponents) {
            year = components.year ?? 0
            month = components.month ?? 0
            day = components.day ?? 0
        }

        init(date: Date, calendar: Calendar) {
            year = calendar.component(.year, from: date)
            month = calendar.component(.month, from: date)
            day = calendar.component(.day, from: date)
        }
    }
}
