import ClarityHubCore
import SwiftUI

struct TodayDashboardView: View {
    let snapshot: DailyClaritySnapshot

    var body: some View {
        ScreenScaffold(title: "Today", subtitle: "One clean read on the day.") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricTile(
                    title: "Weight",
                    value: snapshot.weightTrend.latestWeight.map { "\($0.oneDecimal) lb" } ?? "No data",
                    detail: snapshot.weightTrend.deltaToGoal.map { "\($0.oneDecimal) lb to goal" } ?? "Connect Health",
                    systemImage: "scalemass",
                    tint: .blue
                )
                MetricTile(
                    title: "Habits",
                    value: "\(snapshot.habitsDone)/\(snapshot.habitsDue)",
                    detail: "due today",
                    systemImage: "checkmark.seal",
                    tint: .green
                )
                MetricTile(
                    title: "Tasks",
                    value: "\(snapshot.openTasks.count)",
                    detail: "open priorities",
                    systemImage: "list.bullet.clipboard",
                    tint: .orange
                )
                MetricTile(
                    title: "Nutrition",
                    value: snapshot.nutrition.map { "\($0.calories.formatted(.number.precision(.fractionLength(0)))) cal" } ?? "No import",
                    detail: snapshot.nutrition?.source ?? "Health or Cal AI import",
                    systemImage: "fork.knife.circle",
                    tint: .purple
                )
            }

            SectionPanel(title: "Next actions") {
                ForEach(snapshot.openTasks.prefix(3), id: \.title) { task in
                    HStack {
                        Image(systemName: "circle")
                            .foregroundStyle(.secondary)
                        Text(task.title)
                        Spacer()
                        Text("P\(task.priority)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }

            SectionPanel(title: "Goal signal") {
                ForEach(snapshot.goals, id: \.title) { goal in
                    let progress = GoalProgressCalculator.progress(for: goal, startingValue: 0)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(goal.title)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(progress.fractionComplete, format: .percent.precision(.fractionLength(0)))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: progress.fractionComplete)
                            .tint(.teal)
                    }
                }
            }
        }
    }
}

#Preview {
    TodayDashboardView(snapshot: PreviewData.dailySnapshot)
}

