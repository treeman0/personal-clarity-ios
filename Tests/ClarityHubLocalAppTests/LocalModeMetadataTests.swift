import Foundation
import XCTest
@testable import ClarityHub

final class LocalModeMetadataTests: XCTestCase {
    func testLocalModeDisablesCloudKitInCompiledApp() {
        XCTAssertEqual(ClarityHubBuildConfiguration.mode, .local)
        XCTAssertEqual(ClarityHubBuildConfiguration.cloudKitSync, .disabled)
        XCTAssertEqual(ClarityHubBuildConfiguration.defaultStoreName, "ClarityHubLocal")
    }

    func testLocalAppUsesPersonalBundleAndNoRemoteNotifications() {
        XCTAssertEqual(Bundle.main.bundleIdentifier, "com.treeman0.ClarityHub.Personal")
        XCTAssertNil(Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes"))
    }

    func testLocalGoogleCallbackMatchesCompiledDefault() throws {
        let info = Bundle.main.infoDictionary ?? [:]
        let urlTypes = try XCTUnwrap(info["CFBundleURLTypes"] as? [[String: Any]])
        let firstURLType = try XCTUnwrap(urlTypes.first)
        let schemes = try XCTUnwrap(firstURLType["CFBundleURLSchemes"] as? [String])
        let defaultRedirectScheme = try XCTUnwrap(URL(string: AppPreferences.defaultGoogleRedirectURI)?.scheme)

        XCTAssertEqual(defaultRedirectScheme, "com.treeman0.ClarityHub.Personal")
        XCTAssertTrue(schemes.contains(defaultRedirectScheme))
    }
}
