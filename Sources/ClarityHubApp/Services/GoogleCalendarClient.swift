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
    private let calendarEndpoint = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!

    func upcomingEvents(accessToken: String, now: Date = Date()) async throws -> [CalendarEvent] {
        var components = URLComponents(url: calendarEndpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "timeMin", value: ISO8601DateFormatter.internetDateTime.string(from: now)),
            URLQueryItem(name: "maxResults", value: "20")
        ]

        guard let url = components?.url else {
            throw GoogleCalendarError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw GoogleCalendarError.invalidResponse
        }

        let apiResponse = try JSONDecoder.googleCalendar.decode(GoogleCalendarEventsResponse.self, from: data)
        return apiResponse.items.compactMap(\.calendarEvent)
    }

    private struct GoogleCalendarEventsResponse: Decodable {
        let items: [GoogleCalendarEvent]
    }

    private struct GoogleCalendarEvent: Decodable {
        let id: String
        let summary: String?
        let start: EventDate
        let end: EventDate

        var calendarEvent: CalendarEvent? {
            guard let startDate = start.resolvedDate, let endDate = end.resolvedDate else { return nil }
            return CalendarEvent(
                id: id,
                title: summary ?? "Untitled event",
                startDate: startDate,
                endDate: endDate,
                calendarName: "Google Calendar"
            )
        }
    }

    private struct EventDate: Decodable {
        let date: Date?
        let dateTime: Date?

        var resolvedDate: Date? {
            dateTime ?? date
        }
    }
}

private extension JSONDecoder {
    static var googleCalendar: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)

            if let date = ISO8601DateFormatter.internetDateTimeWithFractionalSeconds.date(from: rawValue) {
                return date
            }

            if let date = ISO8601DateFormatter.internetDateTime.date(from: rawValue) {
                return date
            }

            if let date = DateFormatter.googleCalendarDateOnly.date(from: rawValue) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid Google Calendar date: \(rawValue)")
        }
        return decoder
    }
}

private extension ISO8601DateFormatter {
    static let internetDateTime: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let internetDateTimeWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

private extension DateFormatter {
    static let googleCalendarDateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
