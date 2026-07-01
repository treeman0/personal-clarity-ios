import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayDashboardView()
                .tabItem { Label("Today", systemImage: "sun.max") }

            BodyView()
                .tabItem { Label("Body", systemImage: "figure.strengthtraining.traditional") }

            GoalsView()
                .tabItem { Label("Goals", systemImage: "target") }

            HabitsView()
                .tabItem { Label("Habits", systemImage: "checkmark.circle") }

            ListsView()
                .tabItem { Label("Lists", systemImage: "list.bullet.rectangle") }

            CalendarView(events: PreviewData.calendarEvents)
                .tabItem { Label("Calendar", systemImage: "calendar") }

            NutritionView()
                .tabItem { Label("Nutrition", systemImage: "fork.knife") }

            ReviewView()
                .tabItem { Label("Review", systemImage: "square.and.pencil") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(.teal)
    }
}

#Preview {
    RootTabView()
}
