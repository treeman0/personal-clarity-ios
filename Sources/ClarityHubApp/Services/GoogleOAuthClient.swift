import CryptoKit
import Foundation
import Security

struct GoogleOAuthConfiguration: Equatable {
    let clientID: String
    let redirectURI: String

    var isConfigured: Bool {
        !clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !redirectURI.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var callbackScheme: String? {
        URL(string: redirectURI)?.scheme
    }
}

struct GoogleOAuthRequest: Equatable {
    let authorizationURL: URL
    let codeVerifier: String
    let state: String
}

struct GoogleOAuthClient {
    private let tokenEndpoint = URL(string: "https://oauth2.googleapis.com/token")!
    private let authorizationEndpoint = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
    private let scopes = [
        "https://www.googleapis.com/auth/calendar.events.readonly"
    ]

    func makeAuthorizationRequest(configuration: GoogleOAuthConfiguration) -> GoogleOAuthRequest? {
        guard configuration.isConfigured else { return nil }

        let verifier = Self.randomURLSafeString(byteCount: 64)
        let challenge = Self.codeChallenge(for: verifier)
        let state = Self.randomURLSafeString(byteCount: 24)

        var components = URLComponents(url: authorizationEndpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        guard let authorizationURL = components?.url else { return nil }
        return GoogleOAuthRequest(authorizationURL: authorizationURL, codeVerifier: verifier, state: state)
    }

    func exchangeCode(
        _ code: String,
        codeVerifier: String,
        configuration: GoogleOAuthConfiguration
    ) async throws -> GoogleCalendarTokens {
        try await tokenRequest([
            "client_id": configuration.clientID,
            "code": code,
            "code_verifier": codeVerifier,
            "grant_type": "authorization_code",
            "redirect_uri": configuration.redirectURI
        ])
    }

    func refreshTokens(
        refreshToken: String,
        configuration: GoogleOAuthConfiguration
    ) async throws -> GoogleCalendarTokens {
        let refreshed = try await tokenRequest([
            "client_id": configuration.clientID,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ])

        return GoogleCalendarTokens(
            accessToken: refreshed.accessToken,
            refreshToken: refreshed.refreshToken ?? refreshToken,
            expirationDate: refreshed.expirationDate
        )
    }

    private func tokenRequest(_ fields: [String: String]) async throws -> GoogleCalendarTokens {
        var request = URLRequest(url: tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = fields
            .map { key, value in "\(Self.formEncode(key))=\(Self.formEncode(value))" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw GoogleCalendarError.invalidResponse
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return GoogleCalendarTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expirationDate: tokenResponse.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
        )
    }

    private static func codeChallenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }

    private static func randomURLSafeString(byteCount: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    private static func formEncode(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
        }
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
