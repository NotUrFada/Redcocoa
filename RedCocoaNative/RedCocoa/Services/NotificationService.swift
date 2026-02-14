import Foundation
import UserNotifications
import UIKit

/// Handles push notification permission and device token registration.
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    /// Request notification permission (alert, badge, sound) and register for remote notifications.
    func requestPermissionAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            Task { @MainActor in
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    /// Call when user signs in - save device token to Supabase for this user.
    func saveDeviceTokenIfNeeded(_ token: Data, userId: String) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        Task {
            try? await APIService.saveDeviceToken(userId: userId, token: tokenString)
        }
    }
}
