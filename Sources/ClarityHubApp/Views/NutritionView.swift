import ClarityHubCore
import SwiftData
import SwiftUI

struct NutritionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.nutritionHealthStore) private var nutritionHealthStore
    @Query(sort: \NutritionDayRecord.date, order: .reverse) private var nutritionRecords: [NutritionDayRecord]
    @State private var selectedDate = Date()
    @State private var importSource = NutritionImportSource.calAI
    @State private var importText = ""
    @State private var parsedDay: NutritionDay?
    @State private var statusMessage = ""

    private var day: NutritionDay? {
        RecordDateMatcher.records(nutritionRecords, on: Date()) { $0.date }.first?.day
    }

    private var recentSummary: NutritionSummary {
        NutritionSummaryCalculator.recentAverage(nutritionRecords.map(\.day), limit: 7)
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
                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)

                Picker("Source", selection: $importSource) {
                    Text("Cal AI").tag(NutritionImportSource.calAI)
                    Text("Manual").tag(NutritionImportSource.manual)
                }
                .pickerStyle(.segmented)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $importText)
                        .frame(minHeight: 92)
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    if importText.isEmpty {
                        Text("Calories 2840 Protein 172 Carbs 286 Fat 92")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

                Button {
                    parseImport()
                } label: {
                    Label("Parse import", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let parsedDay {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(importSummary(for: parsedDay))
                            .font(.subheadline.weight(.semibold))
                        Button {
                            save(parsedDay)
                        } label: {
                            Label("Save \(parsedDay.date.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

            SectionPanel(title: "Recent average") {
                if recentSummary.dayCount == 0 {
                    Text("Save a few nutrition days to see your average intake.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("\(recentSummary.dayCount)-day average", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.orange)
                        Text(summaryLine(for: recentSummary))
                            .font(.subheadline)
                    }
                }
            }

            SectionPanel(title: "Recent nutrition") {
                let recent = nutritionRecords.prefix(7)
                if recent.isEmpty {
                    Text("Saved calorie and macro days will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(recent)) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.date, format: .dateTime.month().day().year())
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                                Text("\(record.calories.formatted(.number.precision(.fractionLength(0)))) cal - P \(record.proteinGrams.oneDecimal)g C \(record.carbohydrateGrams.oneDecimal)g F \(record.fatGrams.oneDecimal)g")
                                    .font(.subheadline.weight(.semibold))
                                Text(record.source)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                modelContext.delete(record)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
        .onChange(of: selectedDate) { _, _ in
            clearParsedImport()
        }
        .onChange(of: importSource) { _, _ in
            clearParsedImport()
        }
        .onChange(of: importText) { _, _ in
            clearParsedImport()
        }
    }

    private func parseImport() {
        let trimmed = importText.trimmingCharacters(in: .whitespacesAndNewlines)
        parsedDay = NutritionImportParser.parseDailyTotals(
            trimmed,
            date: selectedDate,
            source: importSource.rawValue
        )
        statusMessage = parsedDay == nil ? "Could not find calories in that import." : "Import parsed. Review before saving."
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
        parsedDay = nil
        importText = ""
        statusMessage = "Saved \(day.date.formatted(date: .abbreviated, time: .omitted))."
    }

    private func clearParsedImport() {
        if parsedDay != nil {
            parsedDay = nil
            statusMessage = ""
        }
    }

    private func connectAndSaveHealthNutrition() async {
        do {
            try await nutritionHealthStore.requestAuthorization()
            if let healthDay = try await nutritionHealthStore.fetchTodayNutrition() {
                save(healthDay)
            } else {
                statusMessage = HealthKitStatusCopy.nutritionNoDataOrPermission
            }
        } catch {
            parsedDay = nil
            statusMessage = HealthKitStatusCopy.nutritionLoadFailed
        }
    }

    private func deleteExistingRecord(on date: Date) {
        RecordDateMatcher.records(nutritionRecords, on: date) { $0.date }.forEach(modelContext.delete)
    }

    private func importSummary(for day: NutritionDay) -> String {
        "\(day.calories.formatted(.number.precision(.fractionLength(0)))) calories, \(day.proteinGrams.oneDecimal)g protein, \(day.carbohydrateGrams.oneDecimal)g carbs, \(day.fatGrams.oneDecimal)g fat"
    }

    private func summaryLine(for summary: NutritionSummary) -> String {
        "\(summary.averageCalories.formatted(.number.precision(.fractionLength(0)))) cal - P \(summary.averageProteinGrams.oneDecimal)g C \(summary.averageCarbohydrateGrams.oneDecimal)g F \(summary.averageFatGrams.oneDecimal)g"
    }
}

private enum NutritionImportSource: String, Hashable {
    case calAI = "Cal AI import"
    case manual = "Manual import"
}
