import UIKit

/// Handles AppDelegate callbacks needed for push notifications (device token).
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Task { @MainActor in
            if let userId = AuthManager.shared.user?.id, userId != "demo" {
                NotificationService.shared.saveDeviceTokenIfNeeded(deviceToken, userId: userId)
            }
            UserDefaults.standard.set(tokenString, forKey: "RedCocoa.deviceToken")
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("Push registration failed: \(error.localizedDescription)")
        #endif
    }
}
