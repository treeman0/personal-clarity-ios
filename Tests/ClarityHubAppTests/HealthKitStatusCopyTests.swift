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
}
