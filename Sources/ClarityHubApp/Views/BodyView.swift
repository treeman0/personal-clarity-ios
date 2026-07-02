import Charts
import ClarityHubCore
import SwiftData
import SwiftUI

struct BodyView: View {
    @Environment(\.healthKitWeightStore) private var healthKitWeightStore
    @Environment(\.weighInReminderScheduler) private var reminderScheduler
    @Query(sort: \AppPreferenceRecord.key) private var preferences: [AppPreferenceRecord]
    @State private var entries: [WeightEntry] = []
    @State private var statusMessage = HealthKitStatusCopy.weightConnectPrompt
    @State private var reminderMessage = ""
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

    private var movingAverageSeries: [WeightMovingAveragePoint] {
        WeightTrendCalculator.movingAverageSeries(entries: entries)
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
                    Chart {
                        ForEach(entries, id: \.date) { entry in
                            LineMark(x: .value("Date", entry.date), y: .value("Weight", entry.pounds))
                                .foregroundStyle(.blue)
                            PointMark(x: .value("Date", entry.date), y: .value("Weight", entry.pounds))
                                .foregroundStyle(.blue)
                        }
                        ForEach(movingAverageSeries, id: \.date) { point in
                            LineMark(x: .value("Date", point.date), y: .value("Moving average", point.pounds))
                                .foregroundStyle(.teal)
                                .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                        RuleMark(y: .value("Goal", goalWeight))
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    }
                    .frame(height: 220)

                    HStack(spacing: 14) {
                        Label("Weight", systemImage: "circle.fill")
                            .foregroundStyle(.blue)
                        Label("Moving average", systemImage: "line.diagonal")
                            .foregroundStyle(.teal)
                        Label("Goal", systemImage: "flag")
                            .foregroundStyle(.green)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            SectionPanel(title: "Automation") {
                Button {
                    Task {
                        do {
                            let scheduled = try await reminderScheduler.authorizeAndScheduleDailyReminder(
                                hour: reminderHour,
                                minute: reminderMinute
                            )
                            reminderMessage = scheduled
                                ? "Daily reminder scheduled for \(reminderLabel)."
                                : "Notification permission was denied."
                        } catch {
                            reminderMessage = "Reminder scheduling failed."
                        }
                    }
                } label: {
                    Label("Schedule \(reminderLabel) weigh-in reminder", systemImage: "bell.badge")
                }
                .buttonStyle(.borderedProminent)

                HStack {
                    Button {
                        Task {
                            do {
                                try await reminderScheduler.snoozeReminder(minutes: 15)
                                reminderMessage = "Snoozed for 15 minutes."
                            } catch {
                                reminderMessage = "Snooze could not be scheduled."
                            }
                        }
                    } label: {
                        Label("Snooze", systemImage: "clock.badge")
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        reminderScheduler.skipPendingSnooze()
                        reminderMessage = "Pending snooze skipped."
                    } label: {
                        Label("Skip snooze", systemImage: "bell.slash")
                    }
                    .buttonStyle(.bordered)
                }

                if !reminderMessage.isEmpty {
                    Text(reminderMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task { await refreshWeight(requestAuthorization: true) }
                } label: {
                    Label(isLoading ? "Loading weight..." : "Connect and refresh Apple Health", systemImage: "heart.text.square")
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
            }
        }
        .task {
            await refreshWeight(requestAuthorization: false)
        }
    }

    private func refreshWeight(requestAuthorization: Bool) async {
        isLoading = true
        defer { isLoading = false }

        do {
            if requestAuthorization {
                try await healthKitWeightStore.requestAuthorization()
            }
            let start = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
            entries = try await healthKitWeightStore.fetchWeights(since: start)
            statusMessage = entries.isEmpty
                ? HealthKitStatusCopy.weightNoDataOrPermission
                : "Loaded \(entries.count) Apple Health weight samples."
        } catch {
            statusMessage = HealthKitStatusCopy.weightLoadFailed
        }
    }
}

#Preview {
    BodyView()
}
