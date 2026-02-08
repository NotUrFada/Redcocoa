import Foundation

/// Tracks all recently messaged chats so the list keeps them in recency order (newest first) until the API reflects them.
enum ChatsOrderStore {
    private static let key = "RedCocoa.lastMessagedByOtherId"
    
    static func setLastMessaged(otherId: String) {
        var map = UserDefaults.standard.dictionary(forKey: key) as? [String: Double] ?? [:]
        map[otherId.lowercased()] = Date().timeIntervalSince1970
        UserDefaults.standard.set(map, forKey: key)
    }
    
    /// Returns the stored timestamp for a chat (when we last messaged them), or nil.
    static func getStoredTimestamp(for otherId: String) -> Date? {
        let map = UserDefaults.standard.dictionary(forKey: key) as? [String: Double] ?? [:]
        guard let ts = map[otherId.lowercased()], ts > 0 else { return nil }
        return Date(timeIntervalSince1970: ts)
    }
    
    /// Clears the stored value when the API now has a last message at least as recent (so we no longer need our override).
    static func clearIfAPIHasCaughtUp(otherId: String, apiLastMessageAt: Date) {
        guard let stored = getStoredTimestamp(for: otherId), apiLastMessageAt >= stored else { return }
        var map = UserDefaults.standard.dictionary(forKey: key) as? [String: Double] ?? [:]
        map.removeValue(forKey: otherId.lowercased())
        UserDefaults.standard.set(map, forKey: key)
    }
}
