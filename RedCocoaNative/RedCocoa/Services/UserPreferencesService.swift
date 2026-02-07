import Foundation

/// App-local preferences (mirrors web UserPreferencesContext)
enum UserPreferencesService {
    private static let defaults = UserDefaults.standard
    private static let keyPrefix = "redcocoa_prefs_"
    
    static var notificationsNewMatches: Bool {
        get { defaults.object(forKey: keyPrefix + "notif_new_matches") as? Bool ?? true }
        set { defaults.set(newValue, forKey: keyPrefix + "notif_new_matches") }
    }
    
    static var notificationsMessages: Bool {
        get { defaults.object(forKey: keyPrefix + "notif_messages") as? Bool ?? true }
        set { defaults.set(newValue, forKey: keyPrefix + "notif_messages") }
    }
    
    static var notificationsAppActivity: Bool {
        get { defaults.object(forKey: keyPrefix + "notif_app_activity") as? Bool ?? false }
        set { defaults.set(newValue, forKey: keyPrefix + "notif_app_activity") }
    }
    
    static var notificationsEnabled: Bool {
        get { defaults.object(forKey: keyPrefix + "notif_enabled") as? Bool ?? false }
        set { defaults.set(newValue, forKey: keyPrefix + "notif_enabled") }
    }
}
