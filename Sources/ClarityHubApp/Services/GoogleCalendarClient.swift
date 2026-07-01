import Foundation

struct CalendarEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarName: String
}

struct CalendarEventDraft: Equatable {
    let title: String
    let startDate: Date
    let endDate: Date
}

enum GoogleCalendarError: Error {
    case missingAccessToken
    case invalidResponse
}

struct GoogleCalendarClient {
    typealias DataLoader = (URLRequest) async throws -> (Data, URLResponse)

    private let calendarEndpoint = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
    private let dataLoader: DataLoader

    init(dataLoader: @escaping DataLoader = { request in
        try await URLSession.shared.data(for: request)
    }) {
        self.dataLoader = dataLoader
    }

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
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await dataLoader(request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw GoogleCalendarError.invalidResponse
        }

        let apiResponse = try JSONDecoder.googleCalendar.decode(GoogleCalendarEventsResponse.self, from: data)
        return apiResponse.items.compactMap(\.calendarEvent)
    }

    func createEvent(accessToken: String, draft: CalendarEventDraft) async throws -> CalendarEvent {
        var request = URLRequest(url: calendarEndpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.googleCalendar.encode(GoogleCalendarCreateRequest(draft: draft))

        let (data, response) = try await dataLoader(request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw GoogleCalendarError.invalidResponse
        }

        guard let event = try JSONDecoder.googleCalendar.decode(GoogleCalendarEvent.self, from: data).calendarEvent else {
            throw GoogleCalendarError.invalidResponse
        }

        return event
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

    private struct GoogleCalendarCreateRequest: Encodable {
        let summary: String
        let start: EventDateTime
        let end: EventDateTime

        init(draft: CalendarEventDraft) {
            summary = draft.title
            start = EventDateTime(dateTime: draft.startDate)
            end = EventDateTime(dateTime: draft.endDate)
        }
    }

    private struct EventDateTime: Encodable {
        let dateTime: Date
        let timeZone = TimeZone.current.identifier
    }

    private struct EventDate: Decodable {
        let date: Date?
        let dateTime: Date?

        var resolvedDate: Date? {
            dateTime ?? date
        }
    }
}

private extension JSONEncoder {
    static var googleCalendar: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(ISO8601DateFormatter.internetDateTime.string(from: date))
        }
        return encoder
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
