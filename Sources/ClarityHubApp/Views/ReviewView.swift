import ClarityHubCore
import SwiftData
import SwiftUI

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyReviewRecord.date, order: .reverse) private var reviews: [DailyReviewRecord]
    @Query(sort: \WeeklyReviewRecord.weekStart, order: .reverse) private var weeklyReviews: [WeeklyReviewRecord]
    @Query(sort: \TaskRecord.createdAt) private var tasks: [TaskRecord]
    @State private var wins = ""
    @State private var friction = ""
    @State private var nextFocus = ""
    @State private var keepDoing = ""
    @State private var changeNextWeek = ""
    @State private var weeklyFocus = ""
    @State private var commitments = ""

    var body: some View {
        ScreenScaffold(title: "Review", subtitle: "Close the loop before tomorrow starts.") {
            reviewField("Wins", text: $wins, prompt: "What moved forward?")
            reviewField("Friction", text: $friction, prompt: "What created drag?")
            reviewField("Next focus", text: $nextFocus, prompt: "What deserves the first block?")

            Button {
                saveReview()
            } label: {
                Label("Save today's review", systemImage: "checkmark")
            }
            .buttonStyle(.borderedProminent)

            SectionPanel(title: "Weekly review") {
                let weekStart = currentWeekStart()
                Text("Week of \(weekStart.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                TextField("What should stay in the system?", text: $keepDoing, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                TextField("What should change next week?", text: $changeNextWeek, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                TextField("Primary weekly focus", text: $weeklyFocus, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                TextField("Concrete commitments", text: $commitments, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)

                Button {
                    saveWeeklyReview()
                } label: {
                    Label("Save weekly review", systemImage: "calendar.badge.checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(weeklyFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            SectionPanel(title: "Recent daily reviews") {
                let recent = reviews.prefix(5)
                if recent.isEmpty {
                    Text("Saved reviews will build a useful memory trail here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(recent)) { review in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(review.date, format: .dateTime.month().day().year())
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Text(review.nextFocus.isEmpty ? "No focus recorded" : review.nextFocus)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
            }

            SectionPanel(title: "Recent weekly reviews") {
                let recent = weeklyReviews.prefix(4)
                if recent.isEmpty {
                    Text("Weekly reviews will show the larger pattern here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(recent)) { review in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Week of \(review.weekStart.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Text(review.focus.isEmpty ? "No focus recorded" : review.focus)
                                .font(.subheadline.weight(.semibold))
                            if !review.commitments.isEmpty {
                                Text(review.commitments)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            loadCurrentDailyReview()
            loadCurrentWeeklyReview()
        }
    }

    private func reviewField(_ title: String, text: Binding<String>, prompt: String) -> some View {
        SectionPanel(title: title) {
            TextField(prompt, text: text, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func saveReview() {
        let reviewDate = Date()
        let todayReviews = RecordDateMatcher.records(reviews, on: reviewDate) { $0.date }
        todayReviews.forEach(modelContext.delete)
        modelContext.insert(DailyReviewRecord(
            date: reviewDate,
            wins: wins.trimmingCharacters(in: .whitespacesAndNewlines),
            friction: friction.trimmingCharacters(in: .whitespacesAndNewlines),
            nextFocus: nextFocus.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        insertFocusTaskIfNeeded(reviewDate: reviewDate)
    }

    private func saveWeeklyReview() {
        let weekStart = currentWeekStart()
        weeklyReviews
            .filter { Calendar.current.isDate($0.weekStart, inSameDayAs: weekStart) }
            .forEach(modelContext.delete)
        modelContext.insert(WeeklyReviewRecord(
            weekStart: weekStart,
            keepDoing: keepDoing.trimmingCharacters(in: .whitespacesAndNewlines),
            changeNextWeek: changeNextWeek.trimmingCharacters(in: .whitespacesAndNewlines),
            focus: weeklyFocus.trimmingCharacters(in: .whitespacesAndNewlines),
            commitments: commitments.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
    }

    private func loadCurrentWeeklyReview() {
        let weekStart = currentWeekStart()
        guard let review = weeklyReviews.first(where: { Calendar.current.isDate($0.weekStart, inSameDayAs: weekStart) }) else {
            return
        }

        keepDoing = review.keepDoing
        changeNextWeek = review.changeNextWeek
        weeklyFocus = review.focus
        commitments = review.commitments
    }

    private func loadCurrentDailyReview() {
        guard let review = RecordDateMatcher.records(reviews, on: Date(), dateKey: { $0.date }).first else {
            return
        }

        wins = review.wins
        friction = review.friction
        nextFocus = review.nextFocus
    }

    private func currentWeekStart() -> Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Calendar.current.startOfDay(for: Date())
    }

    private func insertFocusTaskIfNeeded(reviewDate: Date) {
        guard let action = ReviewFocusPlanner.nextAction(from: nextFocus, reviewDate: reviewDate) else { return }
        let alreadyExists = ReviewFocusPlanner.containsMatchingOpenAction(tasks.map(\.item), action: action)

        guard !alreadyExists else { return }
        modelContext.insert(TaskRecord(
            title: action.title,
            status: action.status.rawValue,
            dueDate: action.dueDate,
            priority: action.priority
        ))
    }
}
