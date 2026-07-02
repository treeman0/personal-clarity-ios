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

    func testPriorityQueuePreservesLinkedContextIDs() {
        let taskID = UUID()
        let listID = UUID()
        let goalID = UUID()
        let projectID = UUID()
        let tasks = [
            TaskItem(
                id: taskID,
                listID: listID,
                goalID: goalID,
                projectID: projectID,
                title: "Goal action",
                status: .open,
                priority: 2
            )
        ]

        let queue = TaskPlanner.priorityQueue(tasks)

        XCTAssertEqual(queue.first?.id, taskID)
        XCTAssertEqual(queue.first?.listID, listID)
        XCTAssertEqual(queue.first?.goalID, goalID)
        XCTAssertEqual(queue.first?.projectID, projectID)
    }

    func testPriorityQueueSortsSamePriorityByDueDateBeforeUndatedTasks() {
        let calendar = Calendar(identifier: .gregorian)
        let earlier = calendar.date(from: DateComponents(year: 2026, month: 7, day: 8))!
        let later = calendar.date(from: DateComponents(year: 2026, month: 7, day: 10))!
        let tasks = [
            TaskItem(title: "Undated", status: .open, priority: 2),
            TaskItem(title: "Later", status: .open, dueDate: later, priority: 2),
            TaskItem(title: "Earlier", status: .open, dueDate: earlier, priority: 2)
        ]

        let queue = TaskPlanner.priorityQueue(tasks)

        XCTAssertEqual(queue.map(\.title), ["Earlier", "Later", "Undated"])
    }
}
