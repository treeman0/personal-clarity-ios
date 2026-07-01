import Charts
import ClarityHubCore
import SwiftData
import SwiftUI

struct BodyView: View {
    @Environment(\.healthKitWeightStore) private var healthKitWeightStore
    @Environment(\.weighInReminderScheduler) private var reminderScheduler
    @Query(sort: \AppPreferenceRecord.key) private var preferences: [AppPreferenceRecord]
    @State private var entries: [WeightEntry] = []
    @State private var statusMessage = "Connect Apple Health to load smart-scale weight."
    @State private var isLoading = false

    private var goalWeight: Double {
        AppPreferences.double(.goalWeightPounds, in: preferences, default: AppPreferences.defaultGoalWeightPounds)
    }

    private var reminderHour: Int {
        AppPreferences.integer(.weighInReminderHour, in: preferences, default: AppPreferences.defaultReminderHour)
    }

    private var reminderMinute: Int {
        AppPreferences.integer(.weighInReminderMinute, in: preferences, default: AppPreferences.defaultReminderMinute)
    }

    private var reminderLabel: String {
        DateComponents(calendar: .current, hour: reminderHour, minute: reminderMinute)
            .date?
            .formatted(date: .omitted, time: .shortened) ?? "morning"
    }

    private var trend: WeightTrend {
        WeightTrendCalculator.trend(entries: entries, goalWeight: goalWeight)
    }

    var body: some View {
        ScreenScaffold(title: "Body", subtitle: "Weight trend, goal distance, and weigh-in rhythm.") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricTile(title: "Current", value: trend.latestWeight.map { "\($0.oneDecimal) lb" } ?? "--", detail: "from Apple Health", systemImage: "scalemass", tint: .blue)
                MetricTile(title: "Goal", value: "\(goalWeight.oneDecimal) lb", detail: trend.deltaToGoal.map { "\($0.oneDecimal) lb remaining" } ?? "set a goal", systemImage: "flag.checkered", tint: .green)
                MetricTile(title: "Average", value: trend.movingAverage.map { "\($0.oneDecimal) lb" } ?? "--", detail: "last 7 weigh-ins", systemImage: "waveform.path.ecg", tint: .teal)
                MetricTile(title: "Streak", value: "\(trend.weighInStreakDays)d", detail: "consecutive days", systemImage: "flame", tint: .orange)
            }

            SectionPanel(title: "Trend") {
                if entries.isEmpty {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                } else {
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
            }

            SectionPanel(title: "Automation") {
                Button {
                    Task {
                        _ = try? await reminderScheduler.requestAuthorization()
                        try? await reminderScheduler.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
                    }
                } label: {
                    Label("Schedule \(reminderLabel) weigh-in reminder", systemImage: "bell.badge")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    Task { await connectAndRefreshWeight() }
                } label: {
                    Label(isLoading ? "Loading weight..." : "Connect and refresh Apple Health", systemImage: "heart.text.square")
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
            }
        }
    }

    private func connectAndRefreshWeight() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await healthKitWeightStore.requestAuthorization()
            let start = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
            entries = try await healthKitWeightStore.fetchWeights(since: start)
            statusMessage = entries.isEmpty ? "No body-weight samples were found in Apple Health." : "Loaded \(entries.count) Apple Health weight samples."
        } catch {
            statusMessage = "Apple Health weight could not be loaded."
        }
    }
}

#Preview {
    BodyView()
}
