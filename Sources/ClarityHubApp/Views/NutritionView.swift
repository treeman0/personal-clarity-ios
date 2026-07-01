import ClarityHubCore
import SwiftData
import SwiftUI

struct NutritionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.nutritionHealthStore) private var nutritionHealthStore
    @Query(sort: \NutritionDayRecord.date, order: .reverse) private var nutritionRecords: [NutritionDayRecord]
    @State private var importText = "Calories 2840 Protein 172 Carbs 286 Fat 92"
    @State private var parsedDay: NutritionDay?

    private var day: NutritionDay? {
        RecordDateMatcher.records(nutritionRecords, on: Date()) { $0.date }.first?.day
    }

    var body: some View {
        ScreenScaffold(title: "Nutrition", subtitle: "Apple Health first, Cal AI import fallback.") {
            if let day {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricTile(title: "Calories", value: day.calories.formatted(.number.precision(.fractionLength(0))), detail: day.source, systemImage: "flame", tint: .orange)
                    MetricTile(title: "Protein", value: "\(day.proteinGrams.oneDecimal)g", detail: "daily total", systemImage: "bolt", tint: .blue)
                    MetricTile(title: "Carbs", value: "\(day.carbohydrateGrams.oneDecimal)g", detail: "daily total", systemImage: "leaf", tint: .green)
                    MetricTile(title: "Fat", value: "\(day.fatGrams.oneDecimal)g", detail: "daily total", systemImage: "drop", tint: .purple)
                }
            } else {
                SectionPanel(title: "Today") {
                    Text("No nutrition total saved for today. Import Cal AI-style totals or connect Apple Health.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
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
                    HStack {
                        Text("\(parsedDay.calories.formatted(.number.precision(.fractionLength(0)))) calories, \(parsedDay.proteinGrams.oneDecimal)g protein")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Button {
                            save(parsedDay)
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            SectionPanel(title: "Apple Health") {
                Button {
                    Task { await connectAndSaveHealthNutrition() }
                } label: {
                    Label("Connect nutrition totals", systemImage: "heart.text.square")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func save(_ day: NutritionDay) {
        deleteExistingRecord(on: day.date)
        modelContext.insert(NutritionDayRecord(
            date: day.date,
            calories: day.calories,
            proteinGrams: day.proteinGrams,
            carbohydrateGrams: day.carbohydrateGrams,
            fatGrams: day.fatGrams,
            source: day.source
        ))
    }

    private func connectAndSaveHealthNutrition() async {
        do {
            try await nutritionHealthStore.requestAuthorization()
            if let healthDay = try await nutritionHealthStore.fetchTodayNutrition() {
                save(healthDay)
            }
        } catch {
            parsedDay = nil
        }
    }

    private func deleteExistingRecord(on date: Date) {
        RecordDateMatcher.records(nutritionRecords, on: date) { $0.date }.forEach(modelContext.delete)
    }
}
