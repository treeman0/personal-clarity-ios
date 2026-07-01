import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.weighInReminderScheduler) private var reminderScheduler
    @Query(sort: \AppPreferenceRecord.key) private var preferences: [AppPreferenceRecord]
    @State private var goalWeight = AppPreferences.defaultGoalWeightPounds
    @State private var reminderDate = Date()
    @State private var saveMessage = ""

    var body: some View {
        ScreenScaffold(title: "Settings", subtitle: "Personal targets and automation timing.") {
            SectionPanel(title: "Body target") {
                Stepper(value: $goalWeight, in: 80...350, step: 0.5) {
                    HStack {
                        Text("Goal weight")
                        Spacer()
                        Text("\(goalWeight.oneDecimal) lb")
                            .font(.body.weight(.semibold))
                    }
                }
            }

            SectionPanel(title: "Morning reminder") {
                DatePicker("Weigh-in time", selection: $reminderDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)

                Button {
                    Task { await saveAndSchedule() }
                } label: {
                    Label("Save and schedule reminder", systemImage: "bell.badge")
                }
                .buttonStyle(.borderedProminent)

                if !saveMessage.isEmpty {
                    Text(saveMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear(perform: loadPreferences)
    }

    private func loadPreferences() {
        goalWeight = AppPreferences.double(
            .goalWeightPounds,
            in: preferences,
            default: AppPreferences.defaultGoalWeightPounds
        )

        let hour = AppPreferences.integer(
            .weighInReminderHour,
            in: preferences,
            default: AppPreferences.defaultReminderHour
        )
        let minute = AppPreferences.integer(
            .weighInReminderMinute,
            in: preferences,
            default: AppPreferences.defaultReminderMinute
        )
        reminderDate = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Self.defaultReminderDate()
    }

    private func saveAndSchedule() async {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
        let hour = components.hour ?? AppPreferences.defaultReminderHour
        let minute = components.minute ?? AppPreferences.defaultReminderMinute

        AppPreferences.upsert(.goalWeightPounds, value: String(goalWeight), in: modelContext, preferences: preferences)
        AppPreferences.upsert(.weighInReminderHour, value: String(hour), in: modelContext, preferences: preferences)
        AppPreferences.upsert(.weighInReminderMinute, value: String(minute), in: modelContext, preferences: preferences)

        do {
            _ = try await reminderScheduler.requestAuthorization()
            try await reminderScheduler.scheduleDailyReminder(hour: hour, minute: minute)
            saveMessage = "Saved and scheduled."
        } catch {
            saveMessage = "Saved, but notification permission or scheduling failed."
        }
    }

    private static func defaultReminderDate() -> Date {
        Calendar.current.date(from: DateComponents(
            hour: AppPreferences.defaultReminderHour,
            minute: AppPreferences.defaultReminderMinute
        )) ?? Date()
    }
}

#Preview {
    SettingsView()
        .modelContainer(try! ClarityHubModelContainerFactory.make(inMemory: true))
}
