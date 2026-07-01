import Charts
import ClarityHubCore
import SwiftUI

struct BodyView: View {
    let entries: [WeightEntry]
    let trend: WeightTrend
    let goalWeight: Double
    @Environment(\.healthKitWeightStore) private var healthKitWeightStore
    @Environment(\.weighInReminderScheduler) private var reminderScheduler

    var body: some View {
        ScreenScaffold(title: "Body", subtitle: "Weight trend, goal distance, and weigh-in rhythm.") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricTile(title: "Current", value: trend.latestWeight.map { "\($0.oneDecimal) lb" } ?? "--", detail: "from Apple Health", systemImage: "scalemass", tint: .blue)
                MetricTile(title: "Goal", value: "\(goalWeight.oneDecimal) lb", detail: trend.deltaToGoal.map { "\($0.oneDecimal) lb remaining" } ?? "set a goal", systemImage: "flag.checkered", tint: .green)
                MetricTile(title: "Average", value: trend.movingAverage.map { "\($0.oneDecimal) lb" } ?? "--", detail: "last 7 weigh-ins", systemImage: "waveform.path.ecg", tint: .teal)
                MetricTile(title: "Streak", value: "\(trend.weighInStreakDays)d", detail: "consecutive days", systemImage: "flame", tint: .orange)
            }

            SectionPanel(title: "Trend") {
                Chart(entries, id: \.date) { entry in
                    LineMark(x: .value("Date", entry.date), y: .value("Weight", entry.pounds))
                        .foregroundStyle(.blue)
                    PointMark(x: .value("Date", entry.date), y: .value("Weight", entry.pounds))
                        .foregroundStyle(.blue)
                    RuleMark(y: .value("Goal", goalWeight))
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                }
                .frame(height: 220)
            }

            SectionPanel(title: "Automation") {
                Button {
                    Task {
                        _ = try? await reminderScheduler.requestAuthorization()
                        try? await reminderScheduler.scheduleDailyReminder(hour: 7, minute: 30)
                    }
                } label: {
                    Label("Schedule 7:30 AM weigh-in reminder", systemImage: "bell.badge")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    Task { try? await healthKitWeightStore.requestAuthorization() }
                } label: {
                    Label("Connect Apple Health weight", systemImage: "heart.text.square")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    BodyView(entries: PreviewData.weights, trend: PreviewData.weightTrend, goalWeight: PreviewData.goalWeight)
}

