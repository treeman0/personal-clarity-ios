import SwiftData
import SwiftUI

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HabitRecord.createdAt) private var habits: [HabitRecord]
    @Query(sort: \HabitCheckInRecord.date) private var checkIns: [HabitCheckInRecord]
    @State private var title = ""
    @State private var cadence = HabitCadence.daily
    @State private var selectedWeekdays = Set(1...7)

    private let weekdays = [
        WeekdayOption(id: 1, label: "Sun"),
        WeekdayOption(id: 2, label: "Mon"),
        WeekdayOption(id: 3, label: "Tue"),
        WeekdayOption(id: 4, label: "Wed"),
        WeekdayOption(id: 5, label: "Thu"),
        WeekdayOption(id: 6, label: "Fri"),
        WeekdayOption(id: 7, label: "Sat")
    ]

    private var habitsDueToday: [HabitRecord] {
        habits.filter(isDueToday)
    }

    var body: some View {
        ScreenScaffold(title: "Habits", subtitle: "Small loops that keep the system honest.") {
            SectionPanel(title: "Add habit") {
                TextField("Habit name", text: $title)
                    .textFieldStyle(.roundedBorder)

                Picker("Cadence", selection: $cadence) {
                    Text("Daily").tag(HabitCadence.daily)
                    Text("Weekly").tag(HabitCadence.weekly)
                }
                .pickerStyle(.segmented)

                if cadence == .weekly {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                        ForEach(weekdays) { weekday in
                            let isSelected = selectedWeekdays.contains(weekday.id)
                            Button {
                                toggleWeekday(weekday.id)
                            } label: {
                                Text(weekday.label)
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity, minHeight: 32)
                            }
                            .buttonStyle(.bordered)
                            .tint(isSelected ? Color.green : Color.secondary)
                        }
                    }
                }

                Button {
                    addHabit()
                } label: {
                    Label("Add habit", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAddHabit)
            }

            SectionPanel(title: "Today") {
                if habitsDueToday.isEmpty {
                    Text(habits.isEmpty ? "Add the routines that keep the larger system moving." : "No habits are scheduled for today.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(habitsDueToday) { habit in
                        let complete = isCompleteToday(habit)
                        Button {
                            toggleToday(habit)
                        } label: {
                            HStack {
                                Image(systemName: complete ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(complete ? .green : .secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(habit.title)
                                    Text(scheduleLabel(for: habit))
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

            SectionPanel(title: "All habits") {
                if habits.isEmpty {
                    Text("Daily and weekly habits will stay visible here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(habits) { habit in
                        HStack {
                            Image(systemName: isDueToday(habit) ? "calendar.badge.clock" : "calendar")
                                .foregroundStyle(isDueToday(habit) ? .green : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(habit.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(scheduleLabel(for: habit))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                deleteHabit(habit)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
    }

    private var canAddHabit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedWeekdaysForCadence.isEmpty
    }

    private var selectedWeekdaysForCadence: Set<Int> {
        cadence == .daily ? Set(1...7) : selectedWeekdays
    }

    private func addHabit() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let weekdays = selectedWeekdaysForCadence
        guard !weekdays.isEmpty else { return }
        modelContext.insert(HabitRecord(title: trimmedTitle, weekdayMask: weekdayMask(for: weekdays)))
        title = ""
        cadence = .daily
        selectedWeekdays = Set(1...7)
    }

    private func isCompleteToday(_ habit: HabitRecord) -> Bool {
        checkIns.contains { $0.habitID == habit.id && $0.state == "done" && Calendar.current.isDateInToday($0.date) }
    }

    private func isDueToday(_ habit: HabitRecord) -> Bool {
        habit.weekdays.contains(Calendar.current.component(.weekday, from: Date()))
    }

    private func toggleToday(_ habit: HabitRecord) {
        if let existing = checkIns.first(where: { $0.habitID == habit.id && Calendar.current.isDateInToday($0.date) }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(HabitCheckInRecord(habitID: habit.id, date: Date()))
        }
    }

    private func toggleWeekday(_ weekday: Int) {
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
        } else {
            selectedWeekdays.insert(weekday)
        }
    }

    private func weekdayMask(for weekdays: Set<Int>) -> Int {
        weekdays.reduce(0) { $0 | (1 << ($1 - 1)) }
    }

    private func scheduleLabel(for habit: HabitRecord) -> String {
        if habit.isDaily {
            return "Daily"
        }

        let labels = weekdays
            .filter { habit.weekdays.contains($0.id) }
            .map(\.label)
            .joined(separator: ", ")

        return labels.isEmpty ? "No days selected" : labels
    }

    private func deleteHabit(_ habit: HabitRecord) {
        checkIns
            .filter { $0.habitID == habit.id }
            .forEach(modelContext.delete)
        modelContext.delete(habit)
    }
}

private enum HabitCadence: Hashable {
    case daily
    case weekly
}

private struct WeekdayOption: Identifiable {
    let id: Int
    let label: String
}
