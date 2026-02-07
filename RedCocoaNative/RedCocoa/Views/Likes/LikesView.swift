import SwiftUI

struct LikesView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var likes: [LikeWithProfile] = []
    @State private var loading = true
    @State private var selectedProfileId: String?
    @State private var selectedChatId: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView()
                        .tint(Color.textOnDark)
                } else if likes.isEmpty {
                    VStack(spacing: 24) {
                        Spacer()
                        Image(systemName: "heart")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.textMuted.opacity(0.8))
                        Text("No likes yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textOnDark)
                        Text("When someone likes you, they'll appear here.")
                            .font(.subheadline)
                            .foregroundStyle(Color.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(likes, id: \.profile.id) { item in
                            Button {
                                selectedProfileId = item.profile.id
                            } label: {
                                LikesCardView(profile: item.profile, status: item.status, isMatch: item.isMatch)
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color.bgDark)
            .navigationTitle("Likes")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selectedProfileId) { id in
                ProfileView(profileId: id, onOpenChat: { selectedChatId = id })
            }
            .navigationDestination(item: $selectedChatId) { id in
                ChatView(otherId: id)
            }
            .task { await load() }
        }
    }
    
    private func load() async {
        do {
            likes = try await APIService.getLikes(userId: auth.user?.id ?? "")
        } catch {
            likes = MockData.profiles.prefix(2).map { LikeWithProfile(profile: $0, status: "Liked you", isMatch: false) }
        }
        loading = false
    }
}

struct LikesCardView: View {
    let profile: Profile
    let status: String
    let isMatch: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: profile.primaryPhoto ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            Image(systemName: "person.circle")
                                .font(.largeTitle)
                                .foregroundStyle(Color.textMuted)
                        }
                }
            }
            .frame(height: 160)
            .clipped()
            
            Text(profile.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textOnDark)
                .padding(8)
            Text(status)
                .font(.caption)
                .foregroundStyle(isMatch ? Color.brand : Color.textMuted)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
        .background(Color.bgCard)
        .cornerRadius(12)
    }
}
