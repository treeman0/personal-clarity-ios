import SwiftData
import SwiftUI

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyReviewRecord.date, order: .reverse) private var reviews: [DailyReviewRecord]
    @State private var wins = ""
    @State private var friction = ""
    @State private var nextFocus = ""

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

            SectionPanel(title: "Recent reviews") {
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
        let todayReviews = RecordDateMatcher.records(reviews, on: Date()) { $0.date }
        todayReviews.forEach(modelContext.delete)
        modelContext.insert(DailyReviewRecord(date: Date(), wins: wins, friction: friction, nextFocus: nextFocus))
    }
}
