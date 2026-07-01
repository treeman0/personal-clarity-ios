import ClarityHubCore
import SwiftUI

struct GoalsView: View {
    let goals: [GoalSnapshot]

    var body: some View {
        ScreenScaffold(title: "Goals", subtitle: "Progress that turns into next action.") {
            ForEach(goals, id: \.title) { goal in
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
                }
            }
        }
    }
}

