import SwiftData
import SwiftUI

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HabitRecord.createdAt) private var habits: [HabitRecord]
    @Query(sort: \HabitCheckInRecord.date) private var checkIns: [HabitCheckInRecord]
    @State private var title = ""

    var body: some View {
        ScreenScaffold(title: "Habits", subtitle: "Small loops that keep the system honest.") {
            SectionPanel(title: "Add daily habit") {
                HStack {
                    TextField("Habit name", text: $title)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        addHabit()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            SectionPanel(title: "Today") {
                if habits.isEmpty {
                    Text("Add the daily routines that keep the larger system moving.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(habits) { habit in
                        let complete = isCompleteToday(habit)
                        Button {
                            toggleToday(habit)
                        } label: {
                            HStack {
                                Image(systemName: complete ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(complete ? .green : .secondary)
                                Text(habit.title)
                                Spacer()
                                Text(habit.isDaily ? "Daily" : "Scheduled")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func addHabit() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        modelContext.insert(HabitRecord(title: trimmedTitle, weekdayMask: HabitRecord.dailyWeekdayMask))
        title = ""
    }

    private func isCompleteToday(_ habit: HabitRecord) -> Bool {
        checkIns.contains { $0.habitID == habit.id && $0.state == "done" && Calendar.current.isDateInToday($0.date) }
    }

    private func toggleToday(_ habit: HabitRecord) {
        if let existing = checkIns.first(where: { $0.habitID == habit.id && Calendar.current.isDateInToday($0.date) }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(HabitCheckInRecord(habitID: habit.id, date: Date()))
        }
    }
}
