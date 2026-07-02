import AuthenticationServices
import SwiftData
import SwiftUI

struct CalendarView: View {
    @Environment(\.googleCalendarClient) private var googleCalendarClient
    @Environment(\.googleCalendarSession) private var calendarSession
    @Query(sort: \AppPreferenceRecord.key) private var preferences: [AppPreferenceRecord]
    @State private var events: [CalendarEvent] = []
    @State private var statusMessage = "Configure and connect Google Calendar to load upcoming events."
    @State private var isLoading = false
    @State private var authSession: ASWebAuthenticationSession?
    @State private var newBlockTitle = "Focus block"
    @State private var newBlockStart = Date()
    @State private var newBlockDurationMinutes = 60

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

                VStack(alignment: .leading, spacing: 10) {
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

                    Button(role: .destructive) {
                        disconnect()
                    } label: {
                        Label("Disconnect", systemImage: "person.crop.circle.badge.xmark")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)
                }
            }

            SectionPanel(title: "Create block") {
                TextField("Block title", text: $newBlockTitle)
                    .textFieldStyle(.roundedBorder)
                DatePicker("Starts", selection: $newBlockStart, displayedComponents: [.date, .hourAndMinute])
                Stepper("Duration \(newBlockDurationMinutes) min", value: $newBlockDurationMinutes, in: 15...240, step: 15)

                Button {
                    Task { await createBlock() }
                } label: {
                    Label("Add to Google Calendar", systemImage: "calendar.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!configuration.isConfigured || isLoading || newBlockTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    private func disconnect() {
        authSession?.cancel()
        authSession = nil
        tokenStore.delete()
        events = []
        statusMessage = "Google Calendar disconnected. Connect again to load events."
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
            apply(CalendarEventCacheUpdate.clear(statusMessage: "Add a Google OAuth client ID in Settings."))
            return
        }

        guard let accessToken = await calendarSession.validAccessToken(configuration: configuration) else {
            apply(CalendarEventCacheUpdate.clear(
                statusMessage: showMissingTokenMessage ? "Connect Google Calendar before refreshing." : nil
            ))
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let loadedEvents = try await googleCalendarClient.upcomingEvents(accessToken: accessToken)
            apply(CalendarEventCacheUpdate.loaded(
                loadedEvents,
                emptyStatusMessage: "No upcoming Google Calendar events found.",
                loadedStatusMessage: "Loaded \(loadedEvents.count) events."
            ))
        } catch {
            apply(CalendarEventCacheUpdate.clear(statusMessage: "Google Calendar events could not be loaded."))
        }
    }

    private func createBlock() async {
        let trimmedTitle = newBlockTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        guard configuration.isConfigured else {
            statusMessage = "Add a Google OAuth client ID in Settings."
            return
        }

        guard let accessToken = await calendarSession.validAccessToken(configuration: configuration) else {
            statusMessage = "Connect Google Calendar before creating blocks."
            return
        }

        isLoading = true
        defer { isLoading = false }

        let endDate = Calendar.current.date(byAdding: .minute, value: newBlockDurationMinutes, to: newBlockStart) ?? newBlockStart
        let draft = CalendarEventDraft(title: trimmedTitle, startDate: newBlockStart, endDate: endDate)

        do {
            _ = try await googleCalendarClient.createEvent(accessToken: accessToken, draft: draft)
            newBlockTitle = "Focus block"
            await refreshEvents()
            statusMessage = "Added \(trimmedTitle) to Google Calendar."
        } catch {
            statusMessage = "Google Calendar block could not be created."
        }
    }

    private func apply(_ update: CalendarEventCacheUpdate) {
        events = update.events
        if let status = update.statusMessage {
            statusMessage = status
        }
    }
}
