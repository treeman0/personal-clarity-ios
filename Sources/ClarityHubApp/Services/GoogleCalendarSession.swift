import Foundation

protocol GoogleCalendarTokenStoring {
    func load() -> GoogleCalendarTokens?
    func save(_ tokens: GoogleCalendarTokens)
}

protocol GoogleOAuthTokenRefreshing {
    func refreshTokens(
        refreshToken: String,
        configuration: GoogleOAuthConfiguration
    ) async throws -> GoogleCalendarTokens
}

struct GoogleCalendarSession {
    private let oauthClient: any GoogleOAuthTokenRefreshing
    private let tokenStore: any GoogleCalendarTokenStoring

    init(
        oauthClient: any GoogleOAuthTokenRefreshing = GoogleOAuthClient(),
        tokenStore: any GoogleCalendarTokenStoring = KeychainTokenStore()
    ) {
        self.oauthClient = oauthClient
        self.tokenStore = tokenStore
    }

    func validAccessToken(configuration: GoogleOAuthConfiguration) async -> String? {
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

extension GoogleOAuthClient: GoogleOAuthTokenRefreshing {}

extension KeychainTokenStore: GoogleCalendarTokenStoring {}
