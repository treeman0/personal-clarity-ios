import Foundation

public enum HabitSchedule {
    public static func isDue(_ habit: HabitPlan, on date: Date, calendar: Calendar = .current) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return habit.weekdays.contains(weekday)
    }

    public static func isComplete(_ habit: HabitPlan, on date: Date, calendar: Calendar = .current) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return habit.completions.contains(components)
    }

    public static func streakDays(
        completionDates: Set<DateComponents>,
        endingOn date: Date,
        calendar: Calendar = .current
    ) -> Int {
        var streak = 0
        var cursor = calendar.startOfDay(for: date)

        while true {
            let components = calendar.dateComponents([.year, .month, .day], from: cursor)
            guard completionDates.contains(components) else { break }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return streak
    }
}

