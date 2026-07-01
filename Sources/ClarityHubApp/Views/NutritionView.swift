import ClarityHubCore
import SwiftUI

struct NutritionView: View {
    let day: NutritionDay
    @Environment(\.nutritionHealthStore) private var nutritionHealthStore
    @State private var importText = "Calories 2840 Protein 172 Carbs 286 Fat 92"
    @State private var parsedDay: NutritionDay?

    var body: some View {
        ScreenScaffold(title: "Nutrition", subtitle: "Apple Health first, Cal AI import fallback.") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricTile(title: "Calories", value: day.calories.formatted(.number.precision(.fractionLength(0))), detail: day.source, systemImage: "flame", tint: .orange)
                MetricTile(title: "Protein", value: "\(day.proteinGrams.oneDecimal)g", detail: "daily total", systemImage: "bolt", tint: .blue)
                MetricTile(title: "Carbs", value: "\(day.carbohydrateGrams.oneDecimal)g", detail: "daily total", systemImage: "leaf", tint: .green)
                MetricTile(title: "Fat", value: "\(day.fatGrams.oneDecimal)g", detail: "daily total", systemImage: "drop", tint: .purple)
            }

            SectionPanel(title: "Import daily totals") {
                TextEditor(text: $importText)
                    .frame(minHeight: 92)
                    .padding(8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button {
                    parsedDay = NutritionImportParser.parseDailyTotals(importText)
                } label: {
                    Label("Parse import", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)

                if let parsedDay {
                    Text("\(parsedDay.calories.formatted(.number.precision(.fractionLength(0)))) calories, \(parsedDay.proteinGrams.oneDecimal)g protein")
                        .font(.subheadline.weight(.semibold))
                }
            }

            SectionPanel(title: "Apple Health") {
                Button {
                    Task { try? await nutritionHealthStore.requestAuthorization() }
                } label: {
                    Label("Connect nutrition totals", systemImage: "heart.text.square")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

