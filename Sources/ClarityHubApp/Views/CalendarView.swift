import AuthenticationServices
import SwiftData
import SwiftUI

struct CalendarView: View {
    @Environment(\.googleCalendarClient) private var googleCalendarClient
    @Query(sort: \AppPreferenceRecord.key) private var preferences: [AppPreferenceRecord]
    @State private var events: [CalendarEvent] = []
    @State private var statusMessage = "Configure and connect Google Calendar to load upcoming events."
    @State private var isLoading = false
    @State private var authSession: ASWebAuthenticationSession?

    private let oauthClient = GoogleOAuthClient()
    private let tokenStore = KeychainTokenStore()

    private var configuration: GoogleOAuthConfiguration {
        GoogleOAuthConfiguration(
            clientID: AppPreferences.string(.googleCalendarClientID, in: preferences),
            redirectURI: AppPreferences.string(
                .googleCalendarRedirectURI,
                in: preferences,
                default: AppPreferences.defaultGoogleRedirectURI
            )
        )
    }

    var body: some View {
        ScreenScaffold(title: "Calendar", subtitle: "The shape of the day without leaving the app.") {
            SectionPanel(title: "Upcoming") {
                if events.isEmpty {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
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
            }

            SectionPanel(title: "Google Calendar") {
                Label(configuration.isConfigured ? "Google OAuth is configured." : "Add a Google OAuth client ID in Settings.", systemImage: configuration.isConfigured ? "lock.open" : "lock.shield")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Button {
                        connect()
                    } label: {
                        Label("Connect", systemImage: "person.crop.circle.badge.checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!configuration.isConfigured || isLoading)

                    Button {
                        Task { await refreshEvents() }
                    } label: {
                        Label(isLoading ? "Loading" : "Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)
                }
            }
        }
        .task {
            await refreshEvents(showMissingTokenMessage: false)
        }
    }

    private func connect() {
        guard
            let request = oauthClient.makeAuthorizationRequest(configuration: configuration),
            let callbackScheme = configuration.callbackScheme
        else {
            statusMessage = "Google Calendar is not configured."
            return
        }

        let session = ASWebAuthenticationSession(
            url: request.authorizationURL,
            callbackURLScheme: callbackScheme
        ) { callbackURL, error in
            Task {
                await finishAuthentication(callbackURL: callbackURL, error: error, request: request)
            }
        }
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = WebAuthenticationPresentationContextProvider.shared
        authSession = session
        session.start()
    }

    private func finishAuthentication(
        callbackURL: URL?,
        error: Error?,
        request: GoogleOAuthRequest
    ) async {
        if error != nil {
            statusMessage = "Google sign-in was cancelled or failed."
            return
        }

        guard
            let callbackURL,
            let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
            components.queryItems?.first(where: { $0.name == "state" })?.value == request.state,
            let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            statusMessage = "Google sign-in returned an invalid response."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let tokens = try await oauthClient.exchangeCode(
                code,
                codeVerifier: request.codeVerifier,
                configuration: configuration
            )
            tokenStore.save(tokens)
            statusMessage = "Google Calendar connected."
            await refreshEvents()
        } catch {
            statusMessage = "Google token exchange failed."
        }
    }

    private func refreshEvents(showMissingTokenMessage: Bool = true) async {
        guard configuration.isConfigured else {
            statusMessage = "Add a Google OAuth client ID in Settings."
            return
        }

        guard let accessToken = await validAccessToken() else {
            if showMissingTokenMessage {
                statusMessage = "Connect Google Calendar before refreshing."
            }
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            events = try await googleCalendarClient.upcomingEvents(accessToken: accessToken)
            statusMessage = events.isEmpty ? "No upcoming Google Calendar events found." : "Loaded \(events.count) events."
        } catch {
            statusMessage = "Google Calendar events could not be loaded."
        }
    }

    private func validAccessToken() async -> String? {
        guard let tokens = tokenStore.load() else { return nil }
        if tokens.isAccessTokenFresh {
            return tokens.accessToken
        }

        guard let refreshToken = tokens.refreshToken else { return nil }
        do {
            let refreshed = try await oauthClient.refreshTokens(refreshToken: refreshToken, configuration: configuration)
            tokenStore.save(refreshed)
            return refreshed.accessToken
        } catch {
            return nil
        }
    }
}
