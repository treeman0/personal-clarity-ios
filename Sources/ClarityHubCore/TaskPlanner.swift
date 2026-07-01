import Foundation

public enum TaskPlanner {
    public static func priorityQueue(_ tasks: [TaskItem], now: Date = Date()) -> [TaskItem] {
        tasks
            .filter { $0.status == .open }
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority {
                    return lhs.priority > rhs.priority
                }

                switch (lhs.dueDate, rhs.dueDate) {
                case let (.some(left), .some(right)):
                    return left < right
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
            }
    }
}

