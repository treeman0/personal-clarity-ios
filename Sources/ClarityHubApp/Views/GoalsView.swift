import ClarityHubCore
import SwiftData
import SwiftUI

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GoalRecord.createdAt) private var goals: [GoalRecord]
    @State private var title = ""
    @State private var currentValue = 0.0
    @State private var targetValue = 100.0
    @State private var direction = GoalDirection.increase

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
                let progress = GoalProgressCalculator.progress(for: goal, startingValue: 0)
                SectionPanel(title: goal.title) {
                    ProgressView(value: progress.fractionComplete)
                        .tint(.teal)
                    HStack {
                        Text("\(goal.currentValue.oneDecimal) now")
                        Spacer()
                        Text("\(goal.targetValue.oneDecimal) target")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            record.currentValue = min(record.targetValue, record.currentValue + 1)
                        } label: {
                            Label("Increase", systemImage: "plus.circle")
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) {
                            modelContext.delete(record)
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
            currentValue: currentValue,
            targetValue: targetValue,
            directionRawValue: direction.rawValue
        ))

        title = ""
        currentValue = 0
        targetValue = 100
        direction = .increase
    }
}
