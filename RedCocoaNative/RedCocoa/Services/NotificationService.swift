import Foundation
import UserNotifications
import UIKit

/// Handles push notification permission, device token registration, and local call notifications.
@MainActor
final class NotificationService {
    static let shared = NotificationService()
    static let incomingCallNotificationId = "RedCocoa.incomingCall"

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

    /// Show a local notification for an incoming call so the user sees a banner/alert.
    func scheduleIncomingCallNotification(callerName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Incoming Call"
        content.body = "\(callerName) is calling you"
        content.sound = .default
        content.categoryIdentifier = "INCOMING_CALL"
        let request = UNNotificationRequest(identifier: Self.incomingCallNotificationId, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.3, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }

    /// Cancel the incoming call notification (e.g. when user answers or declines).
    func cancelIncomingCallNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.incomingCallNotificationId])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Self.incomingCallNotificationId])
    }
}
