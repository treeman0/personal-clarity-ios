import ClarityHubCore
import SwiftData
import SwiftUI

struct TodayDashboardView: View {
    @Environment(\.healthKitWeightStore) private var healthKitWeightStore
    @Environment(\.googleCalendarClient) private var googleCalendarClient
    @Query(sort: \GoalRecord.createdAt) private var goalRecords: [GoalRecord]
    @Query(sort: \HabitRecord.createdAt) private var habitRecords: [HabitRecord]
    @Query(sort: \HabitCheckInRecord.date) private var habitCheckIns: [HabitCheckInRecord]
    @Query(sort: \TaskRecord.createdAt) private var taskRecords: [TaskRecord]
    @Query(sort: \ClarityListRecord.createdAt) private var listRecords: [ClarityListRecord]
    @Query(sort: \ProjectRecord.createdAt) private var projectRecords: [ProjectRecord]
    @Query(sort: \NutritionDayRecord.date, order: .reverse) private var nutritionRecords: [NutritionDayRecord]
    @Query(sort: \DailyReviewRecord.date, order: .reverse) private var reviewRecords: [DailyReviewRecord]
    @Query(sort: \AppPreferenceRecord.key) private var preferences: [AppPreferenceRecord]
    @State private var weightEntries: [WeightEntry] = []
    @State private var weightStatus = "Connect Apple Health to show today's weight."
    @State private var isLoadingWeight = false
    @State private var calendarEvents: [CalendarEvent] = []
    @State private var calendarStatus = "Connect Google Calendar to show today's blocks."
    @State private var isLoadingCalendar = false

    private let calendarSession = GoogleCalendarSession()

    private var goalWeight: Double {
        AppPreferences.double(.goalWeightPounds, in: preferences, default: AppPreferences.defaultGoalWeightPounds)
    }

    private var calendarConfiguration: GoogleOAuthConfiguration {
        GoogleOAuthConfiguration(
            clientID: AppPreferences.string(.googleCalendarClientID, in: preferences),
            redirectURI: AppPreferences.string(
                .googleCalendarRedirectURI,
                in: preferences,
                default: AppPreferences.defaultGoogleRedirectURI
            )
        )
    }

    private var snapshot: DailyClaritySnapshot {
        let today = Date()
        let calendar = Calendar.current
        let dueHabits = habitRecords.filter { $0.weekdays.contains(calendar.component(.weekday, from: today)) }
        let todayCheckIns = RecordDateMatcher.records(habitCheckIns, on: today, calendar: calendar) { $0.date }
        let doneHabitIDs = Set(todayCheckIns.filter { $0.state == "done" }.map(\.habitID))
        let openTasks = TaskPlanner.priorityQueue(taskRecords.map(\.item))
        let nutrition = RecordDateMatcher.records(nutritionRecords, on: today, calendar: calendar) { $0.date }.first?.day

        return DailyClaritySnapshot(
            date: today,
            weightTrend: WeightTrendCalculator.trend(entries: weightEntries, goalWeight: goalWeight, today: today, calendar: calendar),
            goals: goalRecords.map(\.snapshot),
            habitsDue: dueHabits.count,
            habitsDone: dueHabits.filter { doneHabitIDs.contains($0.id) }.count,
            openTasks: openTasks,
            nutrition: nutrition
        )
    }

    private var priorityTaskRecords: [TaskRecord] {
        let orderedIDs = TaskPlanner.priorityQueue(taskRecords.map(\.item)).map(\.id)
        return orderedIDs.compactMap { id in taskRecords.first(where: { $0.id == id }) }
    }

    private var nutritionSummary: NutritionSummary {
        NutritionSummaryCalculator.recentAverage(nutritionRecords.map(\.day), limit: 7)
    }

    var body: some View {
        ScreenScaffold(title: "Today", subtitle: "One clean read on the day.") {
            SetupChecklistView()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricTile(
                    title: "Weight",
                    value: snapshot.weightTrend.latestWeight.map { "\($0.oneDecimal) lb" } ?? "No data",
                    detail: weightDetail,
                    systemImage: "scalemass",
                    tint: .blue
                )
                MetricTile(
                    title: "Habits",
                    value: "\(snapshot.habitsDone)/\(snapshot.habitsDue)",
                    detail: "due today",
                    systemImage: "checkmark.seal",
                    tint: .green
                )
                MetricTile(
                    title: "Tasks",
                    value: "\(snapshot.openTasks.count)",
                    detail: "open priorities",
                    systemImage: "list.bullet.clipboard",
                    tint: .orange
                )
                MetricTile(
                    title: "Nutrition",
                    value: snapshot.nutrition.map { "\($0.calories.formatted(.number.precision(.fractionLength(0)))) cal" } ?? "No import",
                    detail: snapshot.nutrition?.source ?? "Health or Cal AI import",
                    systemImage: "fork.knife.circle",
                    tint: .purple
                )
            }

            SectionPanel(title: "Focus") {
                if let review = latestFocusReview {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "scope")
                            .font(.title3)
                            .foregroundStyle(.teal)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(review.nextFocus)
                                .font(.subheadline.weight(.semibold))
                            Text("From \(review.date.formatted(date: .abbreviated, time: .omitted)) review")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                } else {
                    Text("Save a review focus to carry a clear next action into tomorrow.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            SectionPanel(title: "Next actions") {
                if snapshot.openTasks.isEmpty {
                    Text("No open tasks. Add one in Lists.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(priorityTaskRecords.prefix(3))) { task in
                        Button {
                            task.status = "done"
                        } label: {
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                    Text(taskContext(for: task))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("P\(task.priority)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            SectionPanel(title: "Nutrition signal") {
                if nutritionSummary.dayCount == 0 {
                    Text("Import or connect nutrition to see recent intake here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title3)
                            .foregroundStyle(.orange)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(nutritionSummary.averageCalories.formatted(.number.precision(.fractionLength(0)))) cal average")
                                .font(.subheadline.weight(.semibold))
                            Text("P \(nutritionSummary.averageProteinGrams.oneDecimal)g C \(nutritionSummary.averageCarbohydrateGrams.oneDecimal)g F \(nutritionSummary.averageFatGrams.oneDecimal)g over \(nutritionSummary.dayCount) days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }

            SectionPanel(title: "Calendar blocks") {
                if calendarEvents.isEmpty {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title3)
                            .foregroundStyle(.teal)
                            .frame(width: 28)
                        Text(calendarStatus)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            Task { await refreshCalendar() }
                        } label: {
                            Label(isLoadingCalendar ? "Loading" : "Refresh", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .disabled(isLoadingCalendar)
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(calendarEvents.prefix(4)) { event in
                            HStack(alignment: .top, spacing: 12) {
                                VStack(spacing: 2) {
                                    Text(event.startDate, format: .dateTime.hour().minute())
                                        .font(.caption.weight(.bold))
                                    Text(event.endDate, format: .dateTime.hour().minute())
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 54, alignment: .leading)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(event.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(event.calendarName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                        }

                        Button {
                            Task { await refreshCalendar() }
                        } label: {
                            Label(isLoadingCalendar ? "Loading calendar" : "Refresh calendar", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .disabled(isLoadingCalendar)
                    }
                }
            }

            SectionPanel(title: "Body signal") {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: snapshot.weightTrend.latestWeight == nil ? "heart.text.square" : "scalemass")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(weightStatus)
                            .font(.subheadline.weight(.semibold))
                        if let sevenDayChange = snapshot.weightTrend.sevenDayChange {
                            Text("\(sevenDayChange.oneDecimal) lb over 7 days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Open Body for the full trend and goal line.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        Task { await refreshWeight() }
                    } label: {
                        Label(isLoadingWeight ? "Loading" : "Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoadingWeight)
                }
            }

            SectionPanel(title: "Goal signal") {
                if snapshot.goals.isEmpty {
                    Text("No goals yet. Add your first measurable target in Goals.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(goalRecords) { record in
                        let goal = record.snapshot
                        let progress = GoalProgressCalculator.progress(for: goal)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(goal.title)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(progress.fractionComplete, format: .percent.precision(.fractionLength(0)))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: progress.fractionComplete)
                                .tint(.teal)
                        }
                    }
                }
            }
        }
        .task {
            await refreshWeight()
            await refreshCalendar(showMissingTokenMessage: false)
        }
    }

    private var weightDetail: String {
        if let delta = snapshot.weightTrend.deltaToGoal {
            return "\(delta.oneDecimal) lb to goal"
        }

        if isLoadingWeight {
            return "Loading Health"
        }

        return weightEntries.isEmpty ? "Connect Health" : "Goal unavailable"
    }

    private var latestFocusReview: DailyReviewRecord? {
        reviewRecords.first { !$0.nextFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func refreshWeight() async {
        isLoadingWeight = true
        defer { isLoadingWeight = false }

        do {
            let start = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
            weightEntries = try await healthKitWeightStore.fetchWeights(since: start)
            if let latest = weightEntries.last {
                weightStatus = "Last weigh-in: \(latest.pounds.oneDecimal) lb"
            } else {
                weightStatus = "No Apple Health body-weight samples found yet."
            }
        } catch {
            weightStatus = "Apple Health weight is unavailable. Authorize it in Setup or Body."
        }
    }

    private func refreshCalendar(showMissingTokenMessage: Bool = true) async {
        guard calendarConfiguration.isConfigured else {
            calendarStatus = "Add a Google OAuth client ID in Settings."
            return
        }

        guard let accessToken = await calendarSession.validAccessToken(configuration: calendarConfiguration) else {
            if showMissingTokenMessage {
                calendarStatus = "Connect Google Calendar from the Calendar tab."
            }
            return
        }

        isLoadingCalendar = true
        defer { isLoadingCalendar = false }

        do {
            let events = try await googleCalendarClient.upcomingEvents(accessToken: accessToken)
            calendarEvents = todayEvents(from: events)
            calendarStatus = calendarEvents.isEmpty ? "No remaining Google Calendar blocks today." : "Loaded \(calendarEvents.count) calendar blocks."
        } catch {
            calendarStatus = "Google Calendar blocks could not be loaded."
        }
    }

    private func todayEvents(from events: [CalendarEvent]) -> [CalendarEvent] {
        let now = Date()
        let calendar = Calendar.current
        return events
            .filter { event in
                calendar.isDate(event.startDate, inSameDayAs: now) && event.endDate >= now
            }
            .sorted { $0.startDate < $1.startDate }
    }

    private func goalTitle(for id: UUID?) -> String? {
        guard let id else { return nil }
        return goalRecords.first(where: { $0.id == id })?.title
    }

    private func listTitle(for id: UUID?) -> String? {
        guard let id else { return nil }
        return listRecords.first(where: { $0.id == id })?.title
    }

    private func projectTitle(for id: UUID?) -> String? {
        guard let id else { return nil }
        return projectRecords.first(where: { $0.id == id })?.title
    }

    private func taskContext(for task: TaskRecord) -> String {
        var context = [
            listTitle(for: task.listID),
            projectTitle(for: task.projectID),
            goalTitle(for: task.goalID)
        ].compactMap { $0 }

        if let dueDate = task.dueDate {
            context.insert(dueDetail(for: dueDate), at: 0)
        }

        return context.isEmpty ? "Tap to complete" : context.joined(separator: " - ")
    }

    private func dueDetail(for dueDate: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: dueDate)
        let days = calendar.dateComponents([.day], from: today, to: dueDay).day ?? 0

        switch days {
        case 0:
            return "Due today"
        case 1:
            return "Due tomorrow"
        case let value where value > 1:
            return "Due \(dueDate.formatted(date: .abbreviated, time: .omitted))"
        default:
            return "\(abs(days))d overdue"
        }
    }
}

#Preview {
    TodayDashboardView()
        .modelContainer(try! ClarityHubModelContainerFactory.make(inMemory: true))
}
