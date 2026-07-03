import XCTest
@testable import ClarityHub

final class HealthKitStatusCopyTests: XCTestCase {
    func testWeightNoDataMessageMentionsPermissionRecovery() {
        XCTAssertTrue(HealthKitStatusCopy.weightNoDataOrPermission.contains("denied Health permission"))
        XCTAssertTrue(HealthKitStatusCopy.weightNoDataOrPermission.contains("Health app settings"))
    }

    func testNutritionNoDataMessageMentionsPermissionState() {
        XCTAssertTrue(HealthKitStatusCopy.nutritionNoDataOrPermission.contains("nutrition permission"))
    }

    func testHealthUnavailableCopyIsDistinctFromNoDataAndDeniedCopy() {
        XCTAssertTrue(HealthKitStatusCopy.weightUnavailable.contains("not available on this device"))
        XCTAssertTrue(HealthKitStatusCopy.nutritionUnavailable.contains("not available on this device"))
        XCTAssertFalse(HealthKitStatusCopy.weightUnavailable.contains("denied"))
        XCTAssertFalse(HealthKitStatusCopy.nutritionUnavailable.contains("permission was not granted"))
    }

    func testSetupAuthorizationMessagesSeparateNotificationDenialFromHealthPrompt() {
        XCTAssertTrue(
            HealthKitStatusCopy
                .setupAuthorizationMessage(reminderScheduled: true)
                .contains("confirm access in Health settings")
        )
        XCTAssertTrue(
            HealthKitStatusCopy
                .setupAuthorizationMessage(reminderScheduled: false)
                .contains("notification permission")
        )
    }

    func testSetupAuthorizationMessageNamesDeniedIntegrationAreas() {
        let message = HealthKitStatusCopy.setupAuthorizationMessage(
            bodyAuthorized: false,
            nutritionAuthorized: false,
            reminderScheduled: false
        )

        XCTAssertTrue(message.contains("body-weight Health permission"))
        XCTAssertTrue(message.contains("nutrition Health permission"))
        XCTAssertTrue(message.contains("notification permission"))
        XCTAssertTrue(
            message.contains("Needs attention: body-weight Health permission, nutrition Health permission, notification permission.")
        )
    }

    func testSetupAuthorizationMessageNamesUnavailableHealthData() {
        let message = HealthKitStatusCopy.setupAuthorizationMessage(
            bodyAvailable: false,
            nutritionAvailable: false,
            bodyAuthorized: false,
            nutritionAuthorized: false,
            reminderScheduled: true
        )

        XCTAssertTrue(message.contains("body-weight Health data unavailable"))
        XCTAssertTrue(message.contains("nutrition Health data unavailable"))
        XCTAssertFalse(message.contains("notification permission"))
    }
}
