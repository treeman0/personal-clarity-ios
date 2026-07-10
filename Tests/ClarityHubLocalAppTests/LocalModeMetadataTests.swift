import Foundation
import XCTest
@testable import ClarityHub

final class LocalModeMetadataTests: XCTestCase {
    func testLocalModeDisablesCloudKitInCompiledApp() {
        XCTAssertEqual(ClarityHubBuildConfiguration.mode, .local)
        XCTAssertEqual(ClarityHubBuildConfiguration.cloudKitSync, .disabled)
        XCTAssertEqual(ClarityHubBuildConfiguration.defaultStoreName, "ClarityHubLocal")
        XCTAssertEqual(ClarityHubBuildConfiguration.storageTitle, "On this iPhone")
        XCTAssertEqual(ClarityHubBuildConfiguration.storageDetail, "Local storage, no iCloud sync")
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

    func testLocalTargetCarriesReadOnlyHealthAndPrivacyMetadata() throws {
        let info = Bundle.main.infoDictionary ?? [:]
        let healthDescription = try XCTUnwrap(info["NSHealthShareUsageDescription"] as? String)
        XCTAssertFalse(healthDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertNil(info["NSHealthUpdateUsageDescription"])

        let manifestURL = try XCTUnwrap(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let data = try Data(contentsOf: manifestURL)
        let manifest = try XCTUnwrap(PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any])

        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false)
    }
}
