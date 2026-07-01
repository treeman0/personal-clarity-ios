import Foundation

struct GoogleCalendarSession {
    private let oauthClient = GoogleOAuthClient()
    private let tokenStore = KeychainTokenStore()

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
