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
            currentIndex = 0
            loading = false
            return
        }
        
        let hairFilter = Set(UserDefaults.standard.string(forKey: "filterHairColors")?
            .split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } ?? [])
        let ethnicityFilter = Set(UserDefaults.standard.string(forKey: "filterEthnicities")?
            .split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } ?? [])
        
        do {
            profiles = try await APIService.getDiscoveryProfiles(
                userId: userId,
                hairColorFilter: hairFilter,
                ethnicityFilter: ethnicityFilter
            )
            currentIndex = 0
            loading = false
        } catch {
            profiles = MockData.profiles
            currentIndex = 0
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
        if let userId = uid, !userId.isEmpty, userId != "demo" {
            Task {
                let isMatch = (try? await APIService.likeProfile(userId: userId, likedId: profile.id)) ?? false
                await MainActor.run {
                    if isMatch {
                        onMatch?(profile)
                    } else {
                        advance()
                    }
                }
            }
        } else {
            onMatch?(profile)
        }
    }
    
    func advance() {
        if currentIndex < profiles.count - 1 {
            currentIndex += 1
        }
    }
}
