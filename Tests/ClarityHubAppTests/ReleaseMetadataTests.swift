import Foundation
import XCTest
@testable import ClarityHub

final class ReleaseMetadataTests: XCTestCase {
    func testCloudKitRemoteNotificationBackgroundModeIsDeclared() {
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]

        XCTAssertEqual(modes, ["remote-notification"])
    }

    func testHealthKitUsageDescriptionsArePresent() throws {
        let info = Bundle.main.infoDictionary ?? [:]
        let shareDescription = try XCTUnwrap(info["NSHealthShareUsageDescription"] as? String)
        let updateDescription = try XCTUnwrap(info["NSHealthUpdateUsageDescription"] as? String)

        XCTAssertFalse(shareDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertFalse(updateDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    func testPrivacyManifestDeclaresV1DataCategoriesAndNoTracking() throws {
        let manifestURL = try XCTUnwrap(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let data = try Data(contentsOf: manifestURL)
        let manifest = try XCTUnwrap(PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any])

        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false)

        let collectedTypes = try XCTUnwrap(manifest["NSPrivacyCollectedDataTypes"] as? [[String: Any]])
        let typeNames = Set(collectedTypes.compactMap { $0["NSPrivacyCollectedDataType"] as? String })

        XCTAssertTrue(typeNames.contains("NSPrivacyCollectedDataTypeHealth"))
        XCTAssertTrue(typeNames.contains("NSPrivacyCollectedDataTypeFitness"))
        XCTAssertTrue(typeNames.contains("NSPrivacyCollectedDataTypeOtherUserContent"))
        XCTAssertTrue(typeNames.contains("NSPrivacyCollectedDataTypeProductInteraction"))

        for collectedType in collectedTypes {
            XCTAssertEqual(collectedType["NSPrivacyCollectedDataTypeTracking"] as? Bool, false)
            let purposes = collectedType["NSPrivacyCollectedDataTypePurposes"] as? [String]
            XCTAssertEqual(purposes, ["NSPrivacyCollectedDataTypePurposeAppFunctionality"])
        }
    }
}
