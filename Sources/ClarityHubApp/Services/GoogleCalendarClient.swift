import Foundation

struct CalendarEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarName: String
}

enum GoogleCalendarError: Error {
    case missingAccessToken
    case invalidResponse
}

struct GoogleCalendarClient {
    var accessToken: String? = nil

    func upcomingEvents(now: Date = Date()) async throws -> [CalendarEvent] {
        guard accessToken != nil else {
            return PreviewData.calendarEvents
        }

        // OAuth storage and incremental sync live behind this boundary. V1 UI can ship
        // against the contract while the authorized API flow is wired in App Store setup.
        return PreviewData.calendarEvents.filter { $0.endDate >= now }
    }
}
