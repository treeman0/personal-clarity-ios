import ClarityHubCore
import SwiftData
import SwiftUI

struct ListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskRecord.createdAt) private var taskRecords: [TaskRecord]
    @Query(sort: \GoalRecord.createdAt) private var goals: [GoalRecord]
    @Query(sort: \ClarityListRecord.createdAt) private var lists: [ClarityListRecord]
    @Query(sort: \ProjectRecord.createdAt) private var projects: [ProjectRecord]
    @State private var title = ""
    @State private var priority = 1
    @State private var listTitle = ""
    @State private var listKind = "todo"
    @State private var projectTitle = ""
    @State private var projectOutcome = ""
    @State private var selectedListID: UUID?
    @State private var selectedGoalID: UUID?
    @State private var selectedProjectID: UUID?
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    private var tasks: [TaskRecord] {
        let orderedIDs = TaskPlanner.priorityQueue(taskRecords.map(\.item)).map(\.id)
        return orderedIDs.compactMap { id in
            taskRecords.first(where: { $0.id == id })
        }
    }

    var body: some View {
        ScreenScaffold(title: "Lists", subtitle: "Todos, projects, and reusable lists without clutter.") {
            SectionPanel(title: "Add list") {
                TextField("List name", text: $listTitle)
                    .textFieldStyle(.roundedBorder)
                Picker("Kind", selection: $listKind) {
                    Text("Todo").tag("todo")
                    Text("Project support").tag("project")
                    Text("Reference").tag("reference")
                }
                .pickerStyle(.segmented)
                Button {
                    addList()
                } label: {
                    Label("Add list", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.bordered)
                .disabled(listTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            SectionPanel(title: "Add project") {
                TextField("Project", text: $projectTitle)
                    .textFieldStyle(.roundedBorder)
                TextField("Desired outcome", text: $projectOutcome, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                Button {
                    addProject()
                } label: {
                    Label("Add project", systemImage: "square.stack.3d.up.badge.plus")
                }
                .buttonStyle(.bordered)
                .disabled(projectTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            SectionPanel(title: "Add task") {
                TextField("Task", text: $title)
                    .textFieldStyle(.roundedBorder)
                Stepper("Priority \(priority)", value: $priority, in: 0...5)
                Toggle("Due date", isOn: $hasDueDate)
                if hasDueDate {
                    DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                }
                Picker("List", selection: $selectedListID) {
                    Text("No list").tag(UUID?.none)
                    ForEach(lists) { list in
                        Text(list.title).tag(Optional(list.id))
                    }
                }
                Picker("Project", selection: $selectedProjectID) {
                    Text("No project").tag(UUID?.none)
                    ForEach(projects) { project in
                        Text(project.title).tag(Optional(project.id))
                    }
                }
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

            SectionPanel(title: "Projects") {
                if projects.isEmpty {
                    Text("Projects will collect outcomes and next actions here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(projects) { project in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "square.stack.3d.up")
                                    .foregroundStyle(.teal)
                                Text(project.title)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(openTaskCount(projectID: project.id)) open")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                            if !project.desiredOutcome.isEmpty {
                                Text(project.desiredOutcome)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            SectionPanel(title: "Lists") {
                if lists.isEmpty {
                    Text("Create reusable lists for recurring contexts, projects, and reference buckets.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(lists) { list in
                        HStack {
                            Image(systemName: iconName(for: list.kind))
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(list.title)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(list.kind.capitalized) - \(openTaskCount(listID: list.id)) open")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private func addTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        modelContext.insert(TaskRecord(
            listID: selectedListID,
            goalID: selectedGoalID,
            projectID: selectedProjectID,
            title: trimmedTitle,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority
        ))
        title = ""
        priority = 1
        selectedListID = nil
        selectedGoalID = nil
        selectedProjectID = nil
        hasDueDate = false
        dueDate = Date()
    }

    private func addList() {
        let trimmedTitle = listTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        modelContext.insert(ClarityListRecord(title: trimmedTitle, kind: listKind))
        listTitle = ""
        listKind = "todo"
    }

    private func addProject() {
        let trimmedTitle = projectTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        modelContext.insert(ProjectRecord(
            title: trimmedTitle,
            desiredOutcome: projectOutcome.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        projectTitle = ""
        projectOutcome = ""
    }

    private func taskDetail(for task: TaskRecord) -> String {
        let context = [
            listTitle(for: task.listID),
            projectTitle(for: task.projectID),
            goalTitle(for: task.goalID)
        ].compactMap { $0 }

        var details = ["Priority \(task.priority)"]
        if let dueDate = task.dueDate {
            details.append(dueDetail(for: dueDate))
        }
        details.append(contentsOf: context)

        return details.joined(separator: " - ")
    }

    private func openTaskCount(listID: UUID) -> Int {
        taskRecords.filter { $0.listID == listID && $0.status == "open" }.count
    }

    private func openTaskCount(projectID: UUID) -> Int {
        taskRecords.filter { $0.projectID == projectID && $0.status == "open" }.count
    }

    private func listTitle(for id: UUID?) -> String? {
        guard let id else { return nil }
        return lists.first(where: { $0.id == id })?.title
    }

    private func goalTitle(for id: UUID?) -> String? {
        guard let id else { return nil }
        return goals.first(where: { $0.id == id })?.title
    }

    private func projectTitle(for id: UUID?) -> String? {
        guard let id else { return nil }
        return projects.first(where: { $0.id == id })?.title
    }

    private func iconName(for kind: String) -> String {
        switch kind {
        case "project":
            return "square.stack.3d.up"
        case "reference":
            return "tray.full"
        default:
            return "checklist"
        }
    }

    private func dueDetail(for dueDate: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: dueDate)
        let days = calendar.dateComponents([.day], from: today, to: dueDay).day ?? 0

        switch days {
        case 0:
            return "due today"
        case 1:
            return "due tomorrow"
        case let value where value > 1:
            return "due \(dueDate.formatted(date: .abbreviated, time: .omitted))"
        default:
            return "\(abs(days))d overdue"
        }
    }
}
