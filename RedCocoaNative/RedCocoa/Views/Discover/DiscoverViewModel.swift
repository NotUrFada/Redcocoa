import Foundation
import Supabase

@MainActor
class DiscoverViewModel: ObservableObject {
    @Published var profiles: [Profile] = []
    @Published var currentIndex = 0
    @Published var loading = true
    
    private var passedIds: Set<String> = []
    var userId: String?
    
    var currentProfile: Profile? {
        guard currentIndex < profiles.count else { return nil }
        return profiles[currentIndex]
    }
    
    func load(userId: String) async {
        self.userId = userId
        guard !userId.isEmpty, userId != "demo" else {
            profiles = MockData.profiles
            loading = false
            return
        }
        
        do {
            profiles = try await APIService.getDiscoveryProfiles(userId: userId)
            loading = false
        } catch {
            profiles = MockData.profiles
            loading = false
        }
    }
    
    func pass() {
        guard let profile = currentProfile else { advance(); return }
        advance()
        if let userId = userId, !userId.isEmpty, userId != "demo" {
            Task {
                try? await APIService.passOnProfile(userId: userId, passedId: profile.id)
            }
        } else {
            passedIds.insert(profile.id)
        }
    }
    
    func like(onMatch: ((Profile) -> Void)? = nil) {
        guard let profile = currentProfile else { advance(); return }
        let uid = userId
        advance()
        if let userId = uid, !userId.isEmpty, userId != "demo" {
            Task {
                let isMatch = (try? await APIService.likeProfile(userId: userId, likedId: profile.id)) ?? false
                await MainActor.run {
                    if isMatch { onMatch?(profile) }
                }
            }
        } else {
            onMatch?(profile)
        }
    }
    
    private func advance() {
        if currentIndex < profiles.count - 1 {
            currentIndex += 1
        }
    }
}
