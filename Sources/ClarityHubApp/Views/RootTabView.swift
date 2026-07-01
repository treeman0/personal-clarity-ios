import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayDashboardView(snapshot: PreviewData.dailySnapshot)
                .tabItem { Label("Today", systemImage: "sun.max") }

            BodyView(entries: PreviewData.weights, trend: PreviewData.weightTrend, goalWeight: PreviewData.goalWeight)
                .tabItem { Label("Body", systemImage: "figure.strengthtraining.traditional") }

            GoalsView(goals: PreviewData.goals)
                .tabItem { Label("Goals", systemImage: "target") }

            HabitsView()
                .tabItem { Label("Habits", systemImage: "checkmark.circle") }

            ListsView(tasks: PreviewData.tasks)
                .tabItem { Label("Lists", systemImage: "list.bullet.rectangle") }

            CalendarView(events: PreviewData.calendarEvents)
                .tabItem { Label("Calendar", systemImage: "calendar") }

            NutritionView(day: PreviewData.nutrition)
                .tabItem { Label("Nutrition", systemImage: "fork.knife") }

            ReviewView()
                .tabItem { Label("Review", systemImage: "square.and.pencil") }
        }
        .tint(.teal)
    }
}

#Preview {
    RootTabView()
}

