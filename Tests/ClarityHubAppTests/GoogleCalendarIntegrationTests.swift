import Foundation
import XCTest
@testable import ClarityHub

final class GoogleCalendarIntegrationTests: XCTestCase {
    func testOAuthAuthorizationRequestUsesEventsReadWriteScope() throws {
        let configuration = GoogleOAuthConfiguration(
            clientID: "client-id",
            redirectURI: "com.treeman0.ClarityHub:/oauth2redirect/google"
        )

        let request = try XCTUnwrap(GoogleOAuthClient().makeAuthorizationRequest(configuration: configuration))
        let components = try XCTUnwrap(URLComponents(url: request.authorizationURL, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
            item.value.map { (item.name, $0) }
        })

        XCTAssertEqual(components.host, "accounts.google.com")
        XCTAssertEqual(query["client_id"], "client-id")
        XCTAssertEqual(query["redirect_uri"], configuration.redirectURI)
        XCTAssertEqual(query["response_type"], "code")
        XCTAssertEqual(query["scope"], "https://www.googleapis.com/auth/calendar.events")
        XCTAssertEqual(query["code_challenge_method"], "S256")
        XCTAssertEqual(query["access_type"], "offline")
        XCTAssertFalse(request.codeVerifier.isEmpty)
        XCTAssertFalse(request.state.isEmpty)
    }

    func testOAuthAuthorizationRequestRequiresConfiguration() {
        let configuration = GoogleOAuthConfiguration(clientID: " ", redirectURI: "com.treeman0.ClarityHub:/oauth2redirect/google")

        XCTAssertNil(GoogleOAuthClient().makeAuthorizationRequest(configuration: configuration))
    }

    func testUpcomingEventsBuildsAuthorizedRequestAndDecodesEvents() async throws {
        var capturedRequest: URLRequest?
        let client = GoogleCalendarClient { request in
            capturedRequest = request
            let data = """
            {
              "items": [
                {
                  "id": "event-1",
                  "summary": "Training",
                  "start": { "dateTime": "2026-07-01T15:00:00Z" },
                  "end": { "dateTime": "2026-07-01T16:00:00Z" }
                },
                {
                  "id": "event-2",
                  "start": { "date": "2026-07-02" },
                  "end": { "date": "2026-07-03" }
                }
              ]
            }
            """.data(using: .utf8)!
            return (data, Self.httpResponse(for: request, statusCode: 200))
        }
        let now = try XCTUnwrap(Self.isoDate("2026-07-01T12:00:00Z"))

        let events = try await client.upcomingEvents(accessToken: "access-token", now: now)

        let request = try XCTUnwrap(capturedRequest)
        let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
            item.value.map { (item.name, $0) }
        })
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")
        XCTAssertEqual(components.path, "/calendar/v3/calendars/primary/events")
        XCTAssertEqual(query["singleEvents"], "true")
        XCTAssertEqual(query["orderBy"], "startTime")
        XCTAssertEqual(query["maxResults"], "20")
        XCTAssertEqual(events.map(\.title), ["Training", "Untitled event"])
    }

    func testCreateEventBuildsAuthorizedPostAndDecodesCreatedEvent() async throws {
        var capturedRequest: URLRequest?
        let client = GoogleCalendarClient { request in
            capturedRequest = request
            let data = """
            {
              "id": "created-event",
              "summary": "Focus block",
              "start": { "dateTime": "2026-07-01T18:00:00Z" },
              "end": { "dateTime": "2026-07-01T19:00:00Z" }
            }
            """.data(using: .utf8)!
            return (data, Self.httpResponse(for: request, statusCode: 200))
        }
        let startDate = try XCTUnwrap(Self.isoDate("2026-07-01T18:00:00Z"))
        let endDate = try XCTUnwrap(Self.isoDate("2026-07-01T19:00:00Z"))

        let event = try await client.createEvent(
            accessToken: "access-token",
            draft: CalendarEventDraft(title: "Focus block", startDate: startDate, endDate: endDate)
        )

        let request = try XCTUnwrap(capturedRequest)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let start = try XCTUnwrap(json["start"] as? [String: Any])
        let end = try XCTUnwrap(json["end"] as? [String: Any])

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(json["summary"] as? String, "Focus block")
        XCTAssertEqual(start["dateTime"] as? String, "2026-07-01T18:00:00Z")
        XCTAssertEqual(end["dateTime"] as? String, "2026-07-01T19:00:00Z")
        XCTAssertEqual(event.id, "created-event")
        XCTAssertEqual(event.title, "Focus block")
    }

    func testCalendarClientThrowsOnNonSuccessResponse() async throws {
        let client = GoogleCalendarClient { request in
            ("{}".data(using: .utf8)!, Self.httpResponse(for: request, statusCode: 401))
        }

        do {
            _ = try await client.upcomingEvents(accessToken: "expired")
            XCTFail("Expected upcomingEvents to throw for non-success responses.")
        } catch GoogleCalendarError.invalidResponse {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Expected invalidResponse, got \(error).")
        }
    }

    private static func isoDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    private static func httpResponse(for request: URLRequest, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
