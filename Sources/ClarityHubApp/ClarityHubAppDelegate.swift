import UIKit
import UserNotifications

final class ClarityHubAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        WeighInReminderNotificationActions.registerCategories { categories in
            center.setNotificationCategories(categories)
        }
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await WeighInReminderNotificationActions.handle(actionIdentifier: response.actionIdentifier)
    }
}
