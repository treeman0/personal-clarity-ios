import Foundation
import Security

struct GoogleCalendarTokens: Equatable {
    var accessToken: String
    var refreshToken: String?
    var expirationDate: Date?

    var isAccessTokenFresh: Bool {
        guard let expirationDate else { return true }
        return expirationDate > Date().addingTimeInterval(60)
    }
}

struct KeychainTokenStore {
    private let service = "com.treeman0.ClarityHub.googleCalendar"
    private let account = "oauthTokens"

    func load() -> GoogleCalendarTokens? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(PersistedTokens.self, from: data).tokens
    }

    func save(_ tokens: GoogleCalendarTokens) {
        guard let data = try? JSONEncoder().encode(PersistedTokens(tokens: tokens)) else { return }
        var query = baseQuery()
        let attributes: [String: Any] = [kSecValueData as String: data]

        if SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess {
            SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        } else {
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    func delete() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private struct PersistedTokens: Codable {
        var accessToken: String
        var refreshToken: String?
        var expirationDate: Date?

        init(tokens: GoogleCalendarTokens) {
            accessToken = tokens.accessToken
            refreshToken = tokens.refreshToken
            expirationDate = tokens.expirationDate
        }

        var tokens: GoogleCalendarTokens {
            GoogleCalendarTokens(accessToken: accessToken, refreshToken: refreshToken, expirationDate: expirationDate)
        }
    }
}

