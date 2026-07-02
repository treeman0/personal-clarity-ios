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
                .contains("Notification permission was denied")
        )
    }
}
