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
                            VStack(alignment: .leading, spacing: 20) {
                                Text("People who liked you")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Color.textOnDark.opacity(0.9))
                                    .padding(.horizontal, 16)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(minimum: 140), spacing: 12),
                                    GridItem(.flexible(minimum: 140), spacing: 12)
                                ], spacing: 12) {
                                    ForEach(likes, id: \.profile.id) { item in
                                        LikesCardView(
                                            profile: item.profile,
                                            status: item.status,
                                            isMatch: item.isMatch,
                                            onTap: {
                                                if item.isMatch {
                                                    NotificationCenter.default.post(name: .openChatFromMatch, object: item.profile.id)
                                                } else {
                                                    selectedProfileId = item.profile.id
                                                }
                                            },
                                            onPass: {
                                                Task { await passProfile(item.profile.id) }
                                            }
                                        )
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .clipped()
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 24)
                            }
                            .padding(.top, 20)
                        }
                        .refreshable { await load() }
                    }
                }
                .background(Color.bgDark)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 2) {
                            Text("Likes & Matches")
                                .font(.headline)
                                .foregroundStyle(Color.textOnDark)
                            Text("People who discovered you")
                                .font(.caption)
                                .foregroundStyle(Color.textMuted)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { } label: {
                            Image(systemName: "bell")
                                .foregroundStyle(Color.textOnDark)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
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
                            NotificationCenter.default.post(name: .openChatFromMatch, object: matched.id)
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
    
    private func passProfile(_ id: String) async {
        guard let userId = auth.user?.id else { return }
        try? await APIService.passOnProfile(userId: userId, passedId: id)
        likes.removeAll { $0.profile.id == id }
    }
}

struct LikesCardView: View {
    let profile: Profile
    let status: String
    let isMatch: Bool
    var onTap: () -> Void = {}
    var onPass: (() -> Void)? = nil
    
    private var photoURL: URL? {
        guard let urlString = profile.primaryPhoto, !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }
    
    private var displayName: String {
        let n = profile.name.trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? "Someone" : n
    }
    
    private var locationText: String {
        profile.location ?? "Location unknown"
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image area with MATCH badge - clip applied last so badge stays inside
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
                .overlay(alignment: .topTrailing) {
                    if isMatch {
                        Text("MATCH")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.brand)
                            .clipShape(Capsule())
                            .padding(8)
                    }
                }
                .clipped()
                .frame(maxWidth: .infinity)
                
                // Info area - fixed height for consistent alignment
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(displayName), \(profile.displayAge.map { String($0) } ?? "?")")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.textOnDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.textMuted)
                        Text(locationText)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .truncationMode(.tail)
                    }
                    
                    if isMatch {
                        Text("Send Message")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.brand)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.top, 2)
                    } else if let onPass = onPass {
                        HStack(spacing: 8) {
                            Button { onPass() } label: {
                                Text("✕")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.textOnDark)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.textMuted.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            Button { onTap() } label: {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.brand)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.bgCard)
            }
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.textMuted.opacity(0.15), lineWidth: 1)
            )
            .clipped()
        }
        .buttonStyle(.plain)
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
