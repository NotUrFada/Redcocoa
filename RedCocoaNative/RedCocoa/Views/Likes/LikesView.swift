import SwiftUI

struct LikesView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var likes: [LikeWithProfile] = []
    @State private var loading = true
    @State private var selectedProfileId: String?
    @State private var selectedChatId: String?
    @State private var showMatchOverlay = false
    @State private var matchedProfile: Profile?
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                            ForEach(likes, id: \.profile.id) { item in
                                Button {
                                    selectedProfileId = item.profile.id
                                } label: {
                                    LikesCardView(profile: item.profile, status: item.status, isMatch: item.isMatch)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                    .refreshable { await load() }
                }
            }
            .background(Color.bgDark)
            .navigationTitle("Likes")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selectedProfileId) { id in
                ProfileView(
                    profileId: id,
                    onOpenChat: { selectedChatId = id },
                    onMatch: { profile in
                        matchedProfile = profile
                        showMatchOverlay = true
                    }
                )
            }
            .navigationDestination(item: $selectedChatId) { id in
                ChatView(otherId: id)
            }
            .onAppear { Task { await load() } }
                
                if showMatchOverlay, let matched = matchedProfile {
                    MatchOverlayView(
                        matchedName: matched.name,
                        onDismiss: {
                            selectedChatId = matched.id
                            showMatchOverlay = false
                            matchedProfile = nil
                        }
                    )
                    .transition(.opacity)
                }
            }
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
    
    private var photoURL: URL? {
        guard let urlString = profile.primaryPhoto, !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if let url = photoURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholder
                        case .empty:
                            ZStack {
                                Color.bgCard
                                ProgressView()
                                    .tint(Color.textMuted)
                            }
                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textOnDark)
                    .lineLimit(1)
                Text(status)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isMatch ? Color.brand : Color.textMuted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.bgCard)
        }
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isMatch ? Color.brand.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
    
    private var placeholder: some View {
        ZStack {
            Color.bgDark
            Image(systemName: "person.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.textMuted.opacity(0.5))
        }
    }
}
