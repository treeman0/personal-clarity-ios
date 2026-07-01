import XCTest
@testable import ClarityHubCore

final class TaskPlannerTests: XCTestCase {
    func testPriorityQueueFiltersDoneAndSortsByPriority() {
        let tasks = [
            TaskItem(title: "Low", status: .open, priority: 1),
            TaskItem(title: "Done", status: .done, priority: 10),
            TaskItem(title: "High", status: .open, priority: 3)
        ]

        let queue = TaskPlanner.priorityQueue(tasks)

        XCTAssertEqual(queue.map(\.title), ["High", "Low"])
    }

    func testPriorityQueuePreservesLinkedGoalID() {
        let goalID = UUID()
        let tasks = [
            TaskItem(goalID: goalID, title: "Goal action", status: .open, priority: 2)
        ]

        let queue = TaskPlanner.priorityQueue(tasks)

        XCTAssertEqual(queue.first?.goalID, goalID)
    }
}
