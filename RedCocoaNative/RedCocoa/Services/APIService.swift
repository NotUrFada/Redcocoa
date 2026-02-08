import Foundation
import Supabase

/// API layer mirroring the web app's api.js
enum APIService {
    static var client: SupabaseClient? { SupabaseConfig.client }
    
    // MARK: - Discovery
    static func getDiscoveryProfiles(userId: String) async throws -> [Profile] {
        guard let client = client, userId != "demo" else {
            return MockData.profiles
        }
        
        struct BlockedRow: Decodable { let blocked_id: String }
        struct PassedRow: Decodable { let passed_id: String }
        struct LikeRow: Decodable { let to_user_id: String }
        
        let blocked: [BlockedRow] = (try? await client.from("blocked_users").select("blocked_id").eq("blocker_id", value: userId).execute().value) ?? []
        let passed: [PassedRow] = (try? await client.from("passed_users").select("passed_id").eq("user_id", value: userId).execute().value) ?? []
        let liked: [LikeRow] = (try? await client.from("likes").select("to_user_id").eq("from_user_id", value: userId).execute().value) ?? []
        
        let excludeIds = Set(blocked.map { $0.blocked_id } + passed.map { $0.passed_id } + liked.map { $0.to_user_id })
        
        let all: [Profile] = try await client.from("profiles").select().neq("id", value: userId).execute().value
        
        return all.filter { !excludeIds.contains($0.id) }
    }
    
    static func passOnProfile(userId: String, passedId: String) async throws {
        guard let client = client, userId != "demo" else { return }
        struct PassedInsert: Encodable {
            let user_id: String
            let passed_id: String
        }
        try await client.from("passed_users").upsert(PassedInsert(user_id: userId, passed_id: passedId)).execute()
    }
    
    static func likeProfile(userId: String, likedId: String) async throws -> Bool {
        guard let client = client, userId != "demo" else { return false }
        struct LikeInsert: Encodable {
            let from_user_id: String
            let to_user_id: String
        }
        _ = try? await client.from("likes").insert(LikeInsert(from_user_id: userId, to_user_id: likedId)).execute()
        
        struct LikeCheck: Decodable { let id: String }
        let mutual: [LikeCheck] = (try? await client.from("likes").select("id").eq("from_user_id", value: likedId).eq("to_user_id", value: userId).execute().value) ?? []
        guard !mutual.isEmpty else { return false }
        
        struct MatchInsert: Encodable {
            let user1_id: String
            let user2_id: String
        }
        let u1 = userId < likedId ? userId : likedId
        let u2 = userId < likedId ? likedId : userId
        _ = try? await client.from("matches").upsert(MatchInsert(user1_id: u1, user2_id: u2)).execute()
        return true
    }
    
    // MARK: - Likes
    static func getLikes(userId: String) async throws -> [LikeWithProfile] {
        guard let client = client, userId != "demo" else {
            return MockData.profiles.prefix(2).map { LikeWithProfile(profile: $0, status: "Liked you", isMatch: false) }
        }
        
        struct LikeRow: Decodable { let from_user_id: String }
        struct MatchRow: Decodable { let user1_id: String, user2_id: String }
        
        let likes: [LikeRow] = (try? await client.from("likes").select("from_user_id").eq("to_user_id", value: userId).execute().value) ?? []
        let matchRows: [MatchRow] = (try? await client.from("matches").select("user1_id, user2_id").execute().value) ?? []
        let uid = userId.lowercased()
        let matchIdsLower = Set(matchRows.flatMap { [$0.user1_id, $0.user2_id] }.filter { $0.lowercased() != uid }.map { $0.lowercased() })
        
        // Matches: include in Likes with isMatch true (matches first)
        var matchProfiles: [LikeWithProfile] = []
        if !matchIdsLower.isEmpty {
            let matchIds = Array(matchIdsLower)
            let matchProfs: [Profile] = (try? await client.from("profiles").select().in("id", values: matchIds).execute().value) ?? []
            matchProfiles = matchProfs.map { LikeWithProfile(profile: $0, status: "Match", isMatch: true) }
        }
        
        // Non-match likes
        let likeIds = likes.map { $0.from_user_id }.filter { !matchIdsLower.contains($0.lowercased()) }
        guard !likeIds.isEmpty || !matchProfiles.isEmpty else { return [] }
        
        var result = matchProfiles
        if !likeIds.isEmpty {
            let ids = Array(Set(likeIds))
            let profs: [Profile] = (try? await client.from("profiles").select().in("id", values: ids).execute().value) ?? []
            let byId = Dictionary(uniqueKeysWithValues: profs.map { ($0.id, $0) })
            let likeItems = likes
                .filter { !matchIdsLower.contains($0.from_user_id.lowercased()) }
                .map { like in
                    let p = byId[like.from_user_id] ?? Profile(id: like.from_user_id, name: "Unknown")
                    return LikeWithProfile(profile: p, status: "Liked you", isMatch: false)
                }
            result.append(contentsOf: likeItems)
        }
        return result
    }
    
    // MARK: - Chats
    static func getChats(userId: String) async throws -> [ChatPreview] {
        guard let client = client, userId != "demo" else {
            return MockData.profiles.prefix(2).map { ChatPreview(id: $0.id, name: $0.name, image: $0.primaryPhoto, lastMessage: "No messages yet", time: "", dateStr: "") }
        }
        
        struct MatchRow: Decodable { let id: String, user1_id: String, user2_id: String }
        let matches: [MatchRow] = (try? await client.from("matches").select("id, user1_id, user2_id").execute().value) ?? []
        let uid = userId.lowercased()
        let relevant = matches.filter { $0.user1_id.lowercased() == uid || $0.user2_id.lowercased() == uid }
        let otherIds = relevant.map { $0.user1_id.lowercased() == uid ? $0.user2_id : $0.user1_id }
        guard !otherIds.isEmpty else { return [] }
        
        let matchByOther = Dictionary(uniqueKeysWithValues: relevant.map { row in
            let other = row.user1_id.lowercased() == uid ? row.user2_id : row.user1_id
            return (other, row)
        })
        
        let profs: [Profile] = (try? await client.from("profiles").select().in("id", values: otherIds).execute().value) ?? []
        let profById = Dictionary(uniqueKeysWithValues: profs.map { ($0.id, $0) })
        
        struct LastMsg: Decodable { let match_id: String, content: String, created_at: String }
        let matchIds = relevant.map { $0.id }
        let lastMsgs: [LastMsg] = (try? await client.from("messages").select("match_id, content, created_at").in("match_id", values: matchIds).order("created_at", ascending: false).execute().value) ?? []
        var lastByMatch: [String: LastMsg] = [:]
        for msg in lastMsgs {
            if lastByMatch[msg.match_id] == nil { lastByMatch[msg.match_id] = msg }
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        
        return otherIds.map { id in
            let p = profById[id]
            let m = matchByOther[id]
            let last = m.flatMap { lastByMatch[$0.id] }
            var timeStr = ""
            var dateStr = ""
            if let d = last.flatMap({ ISO8601DateFormatter().date(from: $0.created_at) }) {
                timeStr = timeFormatter.string(from: d)
                dateStr = dateFormatter.string(from: d)
            }
            return ChatPreview(id: id, name: p?.name ?? "Unknown", image: p?.primaryPhoto, lastMessage: last?.content ?? "Tap to chat", time: timeStr, dateStr: dateStr)
        }
    }
    
    static func getMatchId(userId: String, otherId: String) async throws -> String? {
        guard let client = client else { return nil }
        struct MatchId: Decodable { let id: String }
        let m1: MatchId? = try? await client.from("matches").select("id").eq("user1_id", value: userId).eq("user2_id", value: otherId).single().execute().value
        let m2: MatchId? = try? await client.from("matches").select("id").eq("user1_id", value: otherId).eq("user2_id", value: userId).single().execute().value
        return m1?.id ?? m2?.id
    }
    
    static func getMessages(userId: String, otherId: String) async throws -> [ChatMessage] {
        guard let client = client, userId != "demo" else {
            return []
        }
        let matchId = try await getMatchId(userId: userId, otherId: otherId)
        guard let mid = matchId else { return [] }
        
        struct MsgRow: Decodable {
            let id: String
            let content: String
            let sender_id: String
            let created_at: String
            let read_at: String?
        }
        let rows: [MsgRow] = (try? await client.from("messages").select("id, content, sender_id, created_at, read_at").eq("match_id", value: mid).order("created_at", ascending: true).execute().value) ?? []
        
        let outFormatter = DateFormatter()
        outFormatter.dateFormat = "h:mm a"
        
        return rows.map { row in
            let time: Date
            if let d = ISO8601DateFormatter().date(from: row.created_at) {
                time = d
            } else {
                time = Date()
            }
            let readAt: Date? = row.read_at.flatMap { ISO8601DateFormatter().date(from: $0) }
            return ChatMessage(id: row.id, text: row.content, time: outFormatter.string(from: time), sent: row.sender_id.lowercased() == userId.lowercased(), readAt: readAt)
        }
    }
    
    static func markMessagesAsRead(userId: String, matchId: String) async throws {
        guard let client = client, userId != "demo" else { return }
        struct ReadUpdate: Encodable { let read_at: String }
        let now = ISO8601DateFormatter().string(from: Date())
        _ = try? await client.from("messages").update(ReadUpdate(read_at: now)).eq("match_id", value: matchId).neq("sender_id", value: userId).execute()
    }
    
    static func setTyping(matchId: String, userId: String) async throws {
        guard let client = client, userId != "demo" else { return }
        struct TypingRow: Encodable {
            let match_id: String
            let user_id: String
            let updated_at: String
        }
        let now = ISO8601DateFormatter().string(from: Date())
        _ = try? await client.from("typing_indicators").upsert(TypingRow(match_id: matchId, user_id: userId, updated_at: now), onConflict: "match_id, user_id").execute()
    }
    
    static func clearTyping(matchId: String, userId: String) async throws {
        guard let client = client, userId != "demo" else { return }
        _ = try? await client.from("typing_indicators").delete().eq("match_id", value: matchId).eq("user_id", value: userId).execute()
    }
    
    static func isOtherTyping(matchId: String, otherId: String) async -> Bool {
        guard let client = client else { return false }
        struct TypingRow: Decodable { let updated_at: String }
        let rows: [TypingRow] = (try? await client.from("typing_indicators").select("updated_at").eq("match_id", value: matchId).eq("user_id", value: otherId).execute().value) ?? []
        guard let row = rows.first,
              let updated = ISO8601DateFormatter().date(from: row.updated_at) else { return false }
        return Date().timeIntervalSince(updated) < 3
    }
    
    static func sendMessage(userId: String, otherId: String, content: String) async throws {
        guard let client = client else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase not configured"])
        }
        guard userId != "demo" else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign in to send messages"])
        }
        let u1 = userId < otherId ? userId : otherId
        let u2 = userId < otherId ? otherId : userId
        
        struct MatchId: Decodable { let id: String }
        struct MatchInsert: Encodable { let user1_id: String, user2_id: String }
        struct MessageInsert: Encodable {
            let match_id: String, sender_id: String, content: String
        }
        
        var match: MatchId? = try? await client.from("matches").select("id").eq("user1_id", value: u1).eq("user2_id", value: u2).single().execute().value
        if match == nil {
            do {
                try await client.from("matches").insert(MatchInsert(user1_id: u1, user2_id: u2)).execute()
            } catch {
                throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create conversation: \(error.localizedDescription)"])
            }
            match = try? await client.from("matches").select("id").eq("user1_id", value: u1).eq("user2_id", value: u2).single().execute().value
        }
        guard let m = match else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find or create conversation"])
        }
        do {
            try await client.from("messages").insert(MessageInsert(match_id: m.id, sender_id: userId, content: content)).execute()
        } catch {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to send: \(error.localizedDescription)"])
        }
    }
    
    // MARK: - Profile
    static func getProfileById(_ id: String, userId: String?) async throws -> Profile? {
        guard let client = client, id != "demo" else {
            return MockData.profiles.first { $0.id == id } ?? MockData.profiles.first
        }
        return try? await client.from("profiles").select().eq("id", value: id).single().execute().value
    }
    
    // MARK: - Block & Report
    static func blockUser(blockerId: String, blockedId: String) async throws {
        guard let client = client else { return }
        struct BlockedInsert: Encodable {
            let blocker_id: String
            let blocked_id: String
        }
        try await client.from("blocked_users").upsert(BlockedInsert(blocker_id: blockerId, blocked_id: blockedId)).execute()
    }
    
    static func reportUser(reporterId: String, reportedId: String, reason: String) async throws {
        guard let client = client else { return }
        struct ReportInsert: Encodable {
            let reporter_id: String
            let reported_id: String
            let reason: String
        }
        try await client.from("reports").insert(ReportInsert(reporter_id: reporterId, reported_id: reportedId, reason: reason)).execute()
    }
    
    static func updateProfilePhone(userId: String, phone: String) async throws {
        guard let client = client else { return }
        struct Update: Encodable {
            let phone: String
        }
        try await client.from("profiles").update(Update(phone: phone)).eq("id", value: userId).execute()
    }
    
    static func updateProfile(
        userId: String,
        name: String,
        bio: String? = nil,
        location: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        interests: [String]? = nil,
        ethnicity: String? = nil,
        hairColor: String? = nil,
        humorPreference: String? = nil,
        toneVibe: String? = nil,
        badges: [String]? = nil,
        promptResponses: [String: String]? = nil
    ) async throws {
        try await upsertProfile(
            userId: userId, name: name, bio: bio, location: location,
            latitude: latitude, longitude: longitude, interests: interests,
            ethnicity: ethnicity, hairColor: hairColor, humorPreference: humorPreference,
            toneVibe: toneVibe, badges: badges, promptResponses: promptResponses
        )
    }
    
    static func upsertProfile(
        userId: String,
        name: String,
        bio: String? = nil,
        location: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        interests: [String]? = nil,
        ethnicity: String? = nil,
        hairColor: String? = nil,
        humorPreference: String? = nil,
        toneVibe: String? = nil,
        badges: [String]? = nil,
        promptResponses: [String: String]? = nil
    ) async throws {
        guard let client = client else { return }
        struct ProfileRow: Encodable {
            let id: String
            let name: String
            let bio: String?
            let location: String?
            let latitude: Double?
            let longitude: Double?
            let interests: [String]?
            let ethnicity: String?
            let hair_color: String?
            let humor_preference: String?
            let tone_vibe: String?
            let badges: [String]?
            let prompt_responses: [String: String]?
            let updated_at: String
        }
        let formatter = ISO8601DateFormatter()
        let row = ProfileRow(
            id: userId,
            name: name,
            bio: bio,
            location: location,
            latitude: latitude,
            longitude: longitude,
            interests: interests,
            ethnicity: ethnicity,
            hair_color: hairColor,
            humor_preference: humorPreference,
            tone_vibe: toneVibe,
            badges: badges,
            prompt_responses: promptResponses,
            updated_at: formatter.string(from: Date())
        )
        try await client.from("profiles").upsert(row, onConflict: "id").execute()
    }
    
    static func uploadProfilePhoto(userId: String, imageData: Data) async throws -> String {
        guard let client = client else { throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Supabase client"]) }
        let path = "\(userId)/\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        _ = try await client.storage.from("avatars").upload(path, data: imageData)
        let url = try client.storage.from("avatars").getPublicURL(path: path)
        return url.absoluteString
    }
    
    static func uploadProfileVideo(userId: String, videoData: Data, fileExtension: String = "mp4") async throws -> String {
        guard let client = client else { throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Supabase client"]) }
        let path = "\(userId)/videos/\(Int(Date().timeIntervalSince1970 * 1000)).\(fileExtension)"
        _ = try await client.storage.from("avatars").upload(path, data: videoData)
        let url = try client.storage.from("avatars").getPublicURL(path: path)
        return url.absoluteString
    }
    
    static func setProfilePhotos(userId: String, photoUrls: [String], name: String = "User") async throws {
        guard let client = client else { return }
        struct PhotoUpdate: Encodable {
            let id: String
            let name: String
            let photo_urls: [String]
            let updated_at: String
        }
        let formatter = ISO8601DateFormatter()
        try await client.from("profiles").upsert(PhotoUpdate(
            id: userId,
            name: name,
            photo_urls: photoUrls,
            updated_at: formatter.string(from: Date())
        ), onConflict: "id").execute()
    }
    
    static func setProfileMedia(userId: String, photoUrls: [String], videoUrls: [String], name: String = "User") async throws {
        guard let client = client else { return }
        struct MediaUpdate: Encodable {
            let id: String
            let name: String
            let photo_urls: [String]
            let video_urls: [String]
            let updated_at: String
        }
        let formatter = ISO8601DateFormatter()
        try await client.from("profiles").upsert(MediaUpdate(
            id: userId,
            name: name,
            photo_urls: photoUrls,
            video_urls: videoUrls,
            updated_at: formatter.string(from: Date())
        ), onConflict: "id").execute()
    }
}

struct LikeWithProfile {
    let profile: Profile
    let status: String
    let isMatch: Bool
}

struct ChatPreview: Identifiable {
    let id: String
    let name: String
    let image: String?
    let lastMessage: String
    let time: String
    let dateStr: String
}

struct ChatMessage: Identifiable {
    let id: String
    let text: String
    let time: String
    let sent: Bool
    var readAt: Date?
}
