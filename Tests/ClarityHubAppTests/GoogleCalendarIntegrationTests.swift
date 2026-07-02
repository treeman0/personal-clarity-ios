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
        XCTAssertEqual(query["prompt"], "consent")
        XCTAssertFalse(request.codeVerifier.isEmpty)
        XCTAssertFalse(request.state.isEmpty)
    }

    func testOAuthAuthorizationRequestRequiresConfiguration() {
        let configuration = GoogleOAuthConfiguration(clientID: " ", redirectURI: "com.treeman0.ClarityHub:/oauth2redirect/google")

        XCTAssertNil(GoogleOAuthClient().makeAuthorizationRequest(configuration: configuration))
    }

    func testOAuthExchangeBuildsFormRequestAndDecodesTokens() async throws {
        var capturedRequest: URLRequest?
        let client = GoogleOAuthClient { request in
            capturedRequest = request
            let data = """
            {
              "access_token": "access",
              "refresh_token": "refresh",
              "expires_in": 3600
            }
            """.data(using: .utf8)!
            return (data, Self.httpResponse(for: request, statusCode: 200))
        }

        let tokens = try await client.exchangeCode(
            "auth-code",
            codeVerifier: "verifier/value",
            configuration: Self.oauthConfiguration
        )

        let request = try XCTUnwrap(capturedRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
        XCTAssertEqual(request.url?.absoluteString, "https://oauth2.googleapis.com/token")
        let formFields = Self.formFields(from: request)
        XCTAssertEqual(formFields["client_id"], "client-id")
        XCTAssertEqual(formFields["code"], "auth-code")
        XCTAssertEqual(formFields["code_verifier"], "verifier/value")
        XCTAssertEqual(formFields["grant_type"], "authorization_code")
        XCTAssertEqual(formFields["redirect_uri"], Self.oauthConfiguration.redirectURI)
        XCTAssertEqual(tokens.accessToken, "access")
        XCTAssertEqual(tokens.refreshToken, "refresh")
        XCTAssertNotNil(tokens.expirationDate)
    }

    func testOAuthRefreshPreservesExistingRefreshTokenWhenResponseOmitsOne() async throws {
        var capturedRequest: URLRequest?
        let client = GoogleOAuthClient { request in
            capturedRequest = request
            let data = """
            {
              "access_token": "fresh-access",
              "expires_in": 3600
            }
            """.data(using: .utf8)!
            return (data, Self.httpResponse(for: request, statusCode: 200))
        }

        let tokens = try await client.refreshTokens(refreshToken: "existing-refresh", configuration: Self.oauthConfiguration)

        let request = try XCTUnwrap(capturedRequest)
        let formFields = Self.formFields(from: request)
        XCTAssertEqual(formFields["grant_type"], "refresh_token")
        XCTAssertEqual(formFields["refresh_token"], "existing-refresh")
        XCTAssertEqual(tokens.accessToken, "fresh-access")
        XCTAssertEqual(tokens.refreshToken, "existing-refresh")
    }

    func testOAuthTokenRequestThrowsOnNonSuccessResponse() async throws {
        let client = GoogleOAuthClient { request in
            ("{}".data(using: .utf8)!, Self.httpResponse(for: request, statusCode: 400))
        }

        do {
            _ = try await client.refreshTokens(refreshToken: "expired-refresh", configuration: Self.oauthConfiguration)
            XCTFail("Expected token refresh to throw for non-success responses.")
        } catch GoogleCalendarError.invalidResponse {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Expected invalidResponse, got \(error).")
        }
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
        XCTAssertEqual(query["timeMin"], "2026-07-01T12:00:00Z")
        XCTAssertEqual(query["maxResults"], "20")
        XCTAssertEqual(events.map(\.title), ["Training", "Untitled event"])
        XCTAssertEqual(events[1].startDate, try XCTUnwrap(GoogleCalendarDateOnlyParser.date(from: "2026-07-02")))
    }

    func testGoogleCalendarDateOnlyParserUsesProvidedTimeZone() throws {
        let newYork = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let date = try XCTUnwrap(GoogleCalendarDateOnlyParser.date(from: "2026-07-02", timeZone: newYork))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = newYork

        XCTAssertEqual(calendar.component(.year, from: date), 2026)
        XCTAssertEqual(calendar.component(.month, from: date), 7)
        XCTAssertEqual(calendar.component(.day, from: date), 2)
        XCTAssertEqual(calendar.component(.hour, from: date), 0)
        XCTAssertEqual(calendar.component(.minute, from: date), 0)
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

    func testCalendarSessionReturnsFreshAccessTokenWithoutRefreshing() async {
        let tokenStore = InMemoryTokenStore(tokens: GoogleCalendarTokens(
            accessToken: "fresh-access",
            refreshToken: "refresh",
            expirationDate: Date().addingTimeInterval(600)
        ))
        let refresher = StubOAuthRefresher(result: .success(GoogleCalendarTokens(
            accessToken: "new-access",
            refreshToken: "new-refresh",
            expirationDate: Date().addingTimeInterval(600)
        )))
        let session = GoogleCalendarSession(oauthClient: refresher, tokenStore: tokenStore)

        let accessToken = await session.validAccessToken(configuration: Self.oauthConfiguration)

        XCTAssertEqual(accessToken, "fresh-access")
        XCTAssertNil(refresher.requestedRefreshToken)
        XCTAssertNil(tokenStore.savedTokens)
    }

    func testCalendarSessionRefreshesExpiredAccessTokenAndSavesResult() async {
        let tokenStore = InMemoryTokenStore(tokens: GoogleCalendarTokens(
            accessToken: "expired-access",
            refreshToken: "refresh",
            expirationDate: Date().addingTimeInterval(-60)
        ))
        let refreshedTokens = GoogleCalendarTokens(
            accessToken: "new-access",
            refreshToken: "refresh",
            expirationDate: Date().addingTimeInterval(600)
        )
        let refresher = StubOAuthRefresher(result: .success(refreshedTokens))
        let session = GoogleCalendarSession(oauthClient: refresher, tokenStore: tokenStore)

        let accessToken = await session.validAccessToken(configuration: Self.oauthConfiguration)

        XCTAssertEqual(accessToken, "new-access")
        XCTAssertEqual(refresher.requestedRefreshToken, "refresh")
        XCTAssertEqual(refresher.requestedConfiguration, Self.oauthConfiguration)
        XCTAssertEqual(tokenStore.savedTokens, refreshedTokens)
    }

    func testCalendarSessionReturnsNilWhenExpiredTokenCannotRefresh() async {
        let tokenStore = InMemoryTokenStore(tokens: GoogleCalendarTokens(
            accessToken: "expired-access",
            refreshToken: "refresh",
            expirationDate: Date().addingTimeInterval(-60)
        ))
        let refresher = StubOAuthRefresher(result: .failure(GoogleCalendarError.invalidResponse))
        let session = GoogleCalendarSession(oauthClient: refresher, tokenStore: tokenStore)

        let accessToken = await session.validAccessToken(configuration: Self.oauthConfiguration)

        XCTAssertNil(accessToken)
        XCTAssertEqual(refresher.requestedRefreshToken, "refresh")
        XCTAssertNil(tokenStore.savedTokens)
    }

    func testCalendarSessionReturnsNilForExpiredAccessTokenWithoutRefreshToken() async {
        let tokenStore = InMemoryTokenStore(tokens: GoogleCalendarTokens(
            accessToken: "expired-access",
            refreshToken: nil,
            expirationDate: Date().addingTimeInterval(-60)
        ))
        let refresher = StubOAuthRefresher(result: .success(GoogleCalendarTokens(
            accessToken: "unused",
            refreshToken: nil,
            expirationDate: Date().addingTimeInterval(600)
        )))
        let session = GoogleCalendarSession(oauthClient: refresher, tokenStore: tokenStore)

        let accessToken = await session.validAccessToken(configuration: Self.oauthConfiguration)

        XCTAssertNil(accessToken)
        XCTAssertNil(refresher.requestedRefreshToken)
        XCTAssertNil(tokenStore.savedTokens)
    }

    func testCalendarSessionReturnsNilWithoutStoredTokens() async {
        let tokenStore = InMemoryTokenStore(tokens: nil)
        let refresher = StubOAuthRefresher(result: .success(GoogleCalendarTokens(
            accessToken: "unused",
            refreshToken: nil,
            expirationDate: Date().addingTimeInterval(600)
        )))
        let session = GoogleCalendarSession(oauthClient: refresher, tokenStore: tokenStore)

        let accessToken = await session.validAccessToken(configuration: Self.oauthConfiguration)

        XCTAssertNil(accessToken)
        XCTAssertNil(refresher.requestedRefreshToken)
        XCTAssertNil(tokenStore.savedTokens)
    }

    private static let oauthConfiguration = GoogleOAuthConfiguration(
        clientID: "client-id",
        redirectURI: "com.treeman0.ClarityHub:/oauth2redirect/google"
    )

    private static func isoDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    private static func httpResponse(for request: URLRequest, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    private static func formFields(from request: URLRequest) -> [String: String] {
        guard
            let body = request.httpBody,
            let rawBody = String(data: body, encoding: .utf8)
        else {
            return [:]
        }

        var fields: [String: String] = [:]
        for pair in rawBody.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            fields[parts[0].removingPercentEncoding ?? parts[0]] = parts[1].removingPercentEncoding ?? parts[1]
        }
        return fields
    }
}

private final class InMemoryTokenStore: GoogleCalendarTokenStoring {
    private let tokens: GoogleCalendarTokens?
    private(set) var savedTokens: GoogleCalendarTokens?

    init(tokens: GoogleCalendarTokens?) {
        self.tokens = tokens
    }

    func load() -> GoogleCalendarTokens? {
        tokens
    }

    func save(_ tokens: GoogleCalendarTokens) {
        savedTokens = tokens
    }
}

private final class StubOAuthRefresher: GoogleOAuthTokenRefreshing {
    private let result: Result<GoogleCalendarTokens, Error>
    private(set) var requestedRefreshToken: String?
    private(set) var requestedConfiguration: GoogleOAuthConfiguration?

    init(result: Result<GoogleCalendarTokens, Error>) {
        self.result = result
    }

    func refreshTokens(
        refreshToken: String,
        configuration: GoogleOAuthConfiguration
    ) async throws -> GoogleCalendarTokens {
        requestedRefreshToken = refreshToken
        requestedConfiguration = configuration
        return try result.get()
    }
}
