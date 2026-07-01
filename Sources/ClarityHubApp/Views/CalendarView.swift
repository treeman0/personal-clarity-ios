import SwiftUI

struct CalendarView: View {
    let events: [CalendarEvent]
    @Environment(\.googleCalendarClient) private var googleCalendarClient

    var body: some View {
        ScreenScaffold(title: "Calendar", subtitle: "The shape of the day without leaving the app.") {
            SectionPanel(title: "Upcoming") {
                ForEach(events) { event in
                    HStack(alignment: .top) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.teal)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.title)
                                .font(.subheadline.weight(.semibold))
                            Text(event.calendarName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(event.startDate, style: .time)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            SectionPanel(title: "Google Calendar") {
                Label("OAuth and sync are isolated behind the calendar client boundary.", systemImage: "lock.shield")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

