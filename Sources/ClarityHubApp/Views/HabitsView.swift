import SwiftUI

struct HabitsView: View {
    private let habits = [
        ("Weigh in", true),
        ("Protein target", true),
        ("Training", false),
        ("Plan tomorrow", true),
        ("Read", false)
    ]

    var body: some View {
        ScreenScaffold(title: "Habits", subtitle: "Small loops that keep the system honest.") {
            SectionPanel(title: "Today") {
                ForEach(habits, id: \.0) { habit in
                    HStack {
                        Image(systemName: habit.1 ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(habit.1 ? .green : .secondary)
                        Text(habit.0)
                        Spacer()
                    }
                    .font(.body)
                }
            }
        }
    }
}

