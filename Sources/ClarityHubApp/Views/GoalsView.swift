import ClarityHubCore
import SwiftData
import SwiftUI

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GoalRecord.createdAt) private var goals: [GoalRecord]
    @Query(sort: \TaskRecord.createdAt) private var tasks: [TaskRecord]
    @State private var title = ""
    @State private var currentValue = 0.0
    @State private var targetValue = 100.0
    @State private var direction = GoalDirection.increase
    @State private var nextActionTitles: [UUID: String] = [:]

    var body: some View {
        ScreenScaffold(title: "Goals", subtitle: "Progress that turns into next action.") {
            SectionPanel(title: "Add goal") {
                TextField("Goal name", text: $title)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    TextField("Current", value: $currentValue, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    TextField("Target", value: $targetValue, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                Picker("Direction", selection: $direction) {
                    Text("Increase").tag(GoalDirection.increase)
                    Text("Decrease").tag(GoalDirection.decrease)
                    Text("Maintain").tag(GoalDirection.maintain)
                }
                .pickerStyle(.segmented)
                Button {
                    addGoal()
                } label: {
                    Label("Add goal", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if goals.isEmpty {
                SectionPanel(title: "Active goals") {
                    Text("Add a measurable target to start turning intent into tracked progress.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(goals) { record in
                let goal = record.snapshot
                let progress = GoalProgressCalculator.progress(for: goal)
                SectionPanel(title: goal.title) {
                    ProgressView(value: progress.fractionComplete)
                        .tint(.teal)
                    HStack {
                        Text("\(goal.startingValue.oneDecimal) start")
                        Spacer()
                        Text("\(goal.currentValue.oneDecimal) now")
                        Spacer()
                        Text("\(goal.targetValue.oneDecimal) target")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Next actions")
                            .font(.subheadline.weight(.semibold))
                        let linkedTasks = openTasks(for: record)
                        if linkedTasks.isEmpty {
                            Text("Add the next concrete action that would move this goal forward.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(linkedTasks.prefix(3)) { task in
                                Button {
                                    task.status = "done"
                                } label: {
                                    HStack {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                        Text(task.title)
                                            .font(.subheadline)
                                        Spacer()
                                        Text("P\(task.priority)")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack {
                            TextField("Next action", text: nextActionBinding(for: record.id))
                                .textFieldStyle(.roundedBorder)
                            Button {
                                addNextAction(for: record)
                            } label: {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(nextActionTitle(for: record.id).isEmpty)
                        }
                    }

                    HStack {
                        Button {
                            nudge(record)
                        } label: {
                            Label(nudgeLabel(for: goal.direction), systemImage: nudgeSystemImage(for: goal.direction))
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            deleteGoal(record)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private func addGoal() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        modelContext.insert(GoalRecord(
            title: trimmedTitle,
            startingValue: currentValue,
            currentValue: currentValue,
            targetValue: targetValue,
            directionRawValue: direction.rawValue
        ))

        title = ""
        currentValue = 0
        targetValue = 100
        direction = .increase
    }

    private func nudge(_ record: GoalRecord) {
        let direction = GoalDirection(rawValue: record.directionRawValue) ?? .increase
        switch direction {
        case .increase:
            record.currentValue = min(record.targetValue, record.currentValue + 1)
        case .decrease:
            record.currentValue = max(record.targetValue, record.currentValue - 1)
        case .maintain:
            record.currentValue = record.targetValue
        }
    }

    private func nudgeLabel(for direction: GoalDirection) -> String {
        switch direction {
        case .increase:
            return "Increase"
        case .decrease:
            return "Decrease"
        case .maintain:
            return "Set to target"
        }
    }

    private func nudgeSystemImage(for direction: GoalDirection) -> String {
        switch direction {
        case .increase:
            return "plus.circle"
        case .decrease:
            return "minus.circle"
        case .maintain:
            return "scope"
        }
    }

    private func openTasks(for goal: GoalRecord) -> [TaskRecord] {
        tasks
            .filter { $0.goalID == goal.id && $0.status == "open" }
            .sorted {
                if $0.priority != $1.priority {
                    return $0.priority > $1.priority
                }
                return $0.createdAt < $1.createdAt
            }
    }

    private func nextActionBinding(for goalID: UUID) -> Binding<String> {
        Binding(
            get: { nextActionTitles[goalID, default: ""] },
            set: { nextActionTitles[goalID] = $0 }
        )
    }

    private func nextActionTitle(for goalID: UUID) -> String {
        nextActionTitles[goalID, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addNextAction(for goal: GoalRecord) {
        let trimmedTitle = nextActionTitle(for: goal.id)
        guard !trimmedTitle.isEmpty else { return }
        modelContext.insert(TaskRecord(goalID: goal.id, title: trimmedTitle, priority: 2))
        nextActionTitles[goal.id] = ""
    }

    private func deleteGoal(_ goal: GoalRecord) {
        tasks
            .filter { $0.goalID == goal.id }
            .forEach(modelContext.delete)
        modelContext.delete(goal)
    }
}
