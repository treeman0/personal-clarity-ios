import ClarityHubCore
import Foundation

extension GoalRecord {
    var snapshot: GoalSnapshot {
        GoalSnapshot(
            title: title,
            currentValue: currentValue,
            targetValue: targetValue,
            direction: GoalDirection(rawValue: directionRawValue) ?? .increase,
            dueDate: dueDate
        )
    }
}

extension HabitRecord {
    var weekdays: Set<Int> {
        Set((1...7).filter { weekdayMask & (1 << ($0 - 1)) != 0 })
    }

    var isDaily: Bool {
        weekdays.count == 7
    }

    static let dailyWeekdayMask = (1...7).reduce(0) { $0 | (1 << ($1 - 1)) }
}

extension TaskRecord {
    var item: TaskItem {
        TaskItem(
            title: title,
            status: TaskStatus(rawValue: status) ?? .open,
            dueDate: dueDate,
            priority: priority
        )
    }
}

extension NutritionDayRecord {
    var day: NutritionDay {
        NutritionDay(
            date: date,
            calories: calories,
            proteinGrams: proteinGrams,
            carbohydrateGrams: carbohydrateGrams,
            fatGrams: fatGrams,
            source: source
        )
    }
}

enum RecordDateMatcher {
    static func records<T>(
        _ records: [T],
        on date: Date,
        calendar: Calendar = .current,
        dateKey: (T) -> Date
    ) -> [T] {
        records.filter { calendar.isDate(dateKey($0), inSameDayAs: date) }
    }
}

