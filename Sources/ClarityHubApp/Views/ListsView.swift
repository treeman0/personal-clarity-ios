import ClarityHubCore
import SwiftData
import SwiftUI

struct ListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskRecord.createdAt) private var taskRecords: [TaskRecord]
    @Query(sort: \GoalRecord.createdAt) private var goals: [GoalRecord]
    @State private var title = ""
    @State private var priority = 1
    @State private var selectedGoalID: UUID?

    private var tasks: [TaskRecord] {
        taskRecords.filter { $0.status == "open" }.sorted {
            if $0.priority != $1.priority {
                return $0.priority > $1.priority
            }
            return $0.createdAt < $1.createdAt
        }
    }

    var body: some View {
        ScreenScaffold(title: "Lists", subtitle: "Todos, projects, and reusable lists without clutter.") {
            SectionPanel(title: "Add task") {
                TextField("Task", text: $title)
                    .textFieldStyle(.roundedBorder)
                Stepper("Priority \(priority)", value: $priority, in: 0...5)
                Picker("Goal", selection: $selectedGoalID) {
                    Text("No linked goal").tag(UUID?.none)
                    ForEach(goals) { goal in
                        Text(goal.title).tag(Optional(goal.id))
                    }
                }
                Button {
                    addTask()
                } label: {
                    Label("Add task", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            SectionPanel(title: "Priority queue") {
                if tasks.isEmpty {
                    Text("No open tasks. Capture the next concrete action.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(tasks) { task in
                        Button {
                            task.status = "done"
                        } label: {
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                    Text(taskDetail(for: task))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func addTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        modelContext.insert(TaskRecord(goalID: selectedGoalID, title: trimmedTitle, priority: priority))
        title = ""
        priority = 1
        selectedGoalID = nil
    }

    private func taskDetail(for task: TaskRecord) -> String {
        if let goalTitle = goalTitle(for: task.goalID) {
            return "Priority \(task.priority) · \(goalTitle)"
        }

        return "Priority \(task.priority)"
    }

    private func goalTitle(for id: UUID?) -> String? {
        guard let id else { return nil }
        return goals.first(where: { $0.id == id })?.title
    }
}
