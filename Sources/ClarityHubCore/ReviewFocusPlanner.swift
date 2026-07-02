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
}
