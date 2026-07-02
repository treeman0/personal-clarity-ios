import Foundation

public enum ReviewFocusPlanner {
    public static func nextAction(
        from focus: String,
        reviewDate: Date = Date(),
        calendar: Calendar = .current
    ) -> TaskItem? {
        let title = focus.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        let tomorrow = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: reviewDate)
        )

        return TaskItem(title: title, status: .open, dueDate: tomorrow, priority: 3)
    }

    public static func containsMatchingOpenAction(
        _ tasks: [TaskItem],
        action: TaskItem,
        calendar: Calendar = .current
    ) -> Bool {
        tasks.contains { task in
            task.status == .open
                && task.title == action.title
                && sameDueDay(task.dueDate, action.dueDate, calendar: calendar)
        }
    }

    private static func sameDueDay(_ lhs: Date?, _ rhs: Date?, calendar: Calendar) -> Bool {
        switch (lhs, rhs) {
        case let (.some(left), .some(right)):
            return calendar.isDate(left, inSameDayAs: right)
        case (.none, .none):
            return true
        default:
            return false
        }
    }
}
