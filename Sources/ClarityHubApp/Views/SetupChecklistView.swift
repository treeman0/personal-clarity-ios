import SwiftData
import SwiftUI

struct SetupChecklistView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.healthKitWeightStore) private var healthKitWeightStore
    @Environment(\.nutritionHealthStore) private var nutritionHealthStore
    @Environment(\.weighInReminderScheduler) private var reminderScheduler
    @Query(sort: \AppPreferenceRecord.key) private var preferences: [AppPreferenceRecord]
    @Query(sort: \GoalRecord.createdAt) private var goals: [GoalRecord]
    @Query(sort: \HabitRecord.createdAt) private var habits: [HabitRecord]
    @Query(sort: \TaskRecord.createdAt) private var tasks: [TaskRecord]
    @Query(sort: \NutritionDayRecord.date, order: .reverse) private var nutritionRecords: [NutritionDayRecord]
    @State private var statusMessage = ""

    private var setupProgress: Double {
        let completedCount = checklistItems.filter(\.isComplete).count
        return Double(completedCount) / Double(checklistItems.count)
    }

    private var checklistItems: [SetupChecklistItem] {
        [
            SetupChecklistItem(
                title: "Body target",
                detail: "\(goalWeight.oneDecimal) lb goal",
                systemImage: "flag.checkered",
                isComplete: hasPreference(.goalWeightPounds)
            ),
            SetupChecklistItem(
                title: "Morning reminder",
                detail: reminderTimeLabel,
                systemImage: "bell.badge",
                isComplete: hasPreference(.weighInReminderHour) && hasPreference(.weighInReminderMinute)
            ),
            SetupChecklistItem(
                title: "Google Calendar",
                detail: googleCalendarConfigured ? "OAuth client saved" : "Client ID needed",
                systemImage: "calendar",
                isComplete: googleCalendarConfigured
            ),
            SetupChecklistItem(
                title: "First goal",
                detail: goals.isEmpty ? "Add a measurable target" : "\(goals.count) active",
                systemImage: "target",
                isComplete: !goals.isEmpty
            ),
            SetupChecklistItem(
                title: "First habit",
                detail: habits.isEmpty ? "Add a daily loop" : "\(habits.count) tracked",
                systemImage: "checkmark.circle",
                isComplete: !habits.isEmpty
            ),
            SetupChecklistItem(
                title: "Task capture",
                detail: tasks.contains { $0.status == "open" } ? "Open task ready" : "Capture a next action",
                systemImage: "list.bullet.rectangle",
                isComplete: tasks.contains { $0.status == "open" || $0.status == "done" }
            ),
            SetupChecklistItem(
                title: "Nutrition path",
                detail: nutritionRecords.isEmpty ? "Import or connect Health" : "Daily total saved",
                systemImage: "fork.knife",
                isComplete: !nutritionRecords.isEmpty
            )
        ]
    }

    private var goalWeight: Double {
        AppPreferences.double(.goalWeightPounds, in: preferences, default: AppPreferences.defaultGoalWeightPounds)
    }

    private var reminderHour: Int {
        AppPreferences.integer(.weighInReminderHour, in: preferences, default: AppPreferences.defaultReminderHour)
    }

    private var reminderMinute: Int {
        AppPreferences.integer(.weighInReminderMinute, in: preferences, default: AppPreferences.defaultReminderMinute)
    }

    private var reminderTimeLabel: String {
        Calendar.current
            .date(from: DateComponents(hour: reminderHour, minute: reminderMinute))?
            .formatted(date: .omitted, time: .shortened) ?? "Set in Settings"
    }

    private var googleCalendarConfigured: Bool {
        !AppPreferences.string(.googleCalendarClientID, in: preferences)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    var body: some View {
        SectionPanel(title: "Setup") {
            VStack(alignment: .leading, spacing: 10) {
                ProgressView(value: setupProgress)
                    .tint(.teal)

                ForEach(checklistItems) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.isComplete ? "checkmark.circle.fill" : item.systemImage)
                            .foregroundStyle(item.isComplete ? .green : .secondary)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                HStack {
                    Button {
                        saveDefaultBodySettings()
                    } label: {
                        Label("Use defaults", systemImage: "slider.horizontal.3")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        Task { await authorizeCoreIntegrations() }
                    } label: {
                        Label("Authorize", systemImage: "lock.open")
                    }
                    .buttonStyle(.borderedProminent)
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func hasPreference(_ key: AppPreferenceKey) -> Bool {
        preferences.contains { $0.key == key.rawValue }
    }

    private func saveDefaultBodySettings() {
        AppPreferences.upsert(
            .goalWeightPounds,
            value: String(goalWeight),
            in: modelContext,
            preferences: preferences
        )
        AppPreferences.upsert(
            .weighInReminderHour,
            value: String(reminderHour),
            in: modelContext,
            preferences: preferences
        )
        AppPreferences.upsert(
            .weighInReminderMinute,
            value: String(reminderMinute),
            in: modelContext,
            preferences: preferences
        )
        statusMessage = "Default body settings saved."
    }

    private func authorizeCoreIntegrations() async {
        do {
            try await healthKitWeightStore.requestAuthorization()
            try await nutritionHealthStore.requestAuthorization()
            _ = try await reminderScheduler.requestAuthorization()
            try await reminderScheduler.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
            statusMessage = "Health and reminder permissions requested."
        } catch {
            statusMessage = "Some permissions could not be completed."
        }
    }
}

private struct SetupChecklistItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let systemImage: String
    let isComplete: Bool
}

#Preview {
    SetupChecklistView()
        .modelContainer(try! ClarityHubModelContainerFactory.make(inMemory: true))
}

