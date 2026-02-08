import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var selectedProfileId: String?
    @State private var selectedChatId: String?
    @State private var showFilters = false
    @State private var showMatchOverlay = false
    @State private var matchedProfile: Profile?
    @State private var showProfilePreview = false
    var profileRefreshTrigger: UUID = UUID()
    var onProfileTap: (() -> Void)? = nil
    var onMatch: (() -> Void)? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgDark.ignoresSafeArea()
                if viewModel.loading {
                    ProgressView("Loading profiles...")
                        .foregroundStyle(Color.textOnDark)
                } else if viewModel.profiles.isEmpty || viewModel.currentProfile == nil {
                    EmptyDiscoverView(onAdjustFilters: {})
                } else if let profile = viewModel.currentProfile {
                    DiscoverCardStack(
                        profile: profile,
                        onPass: { viewModel.pass() },
                        onLike: { viewModel.like { matched in
                            matchedProfile = matched
                            showMatchOverlay = true
                            onMatch?()
                        } },
                        onMessage: { selectedChatId = profile.id },
                        onTap: { selectedProfileId = profile.id }
                    )
                }
                
                if showMatchOverlay, let matched = matchedProfile {
                    MatchOverlayView(
                        matchedName: matched.name,
                        onDismiss: {
                            showMatchOverlay = false
                            matchedProfile = nil
                            viewModel.advance()
                            NotificationCenter.default.post(name: .openChatFromMatch, object: matched.id)
                        }
                    )
                    .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        profileAvatar
                        Button {
                            showProfilePreview = true
                        } label: {
                            Image(systemName: "eye")
                                .foregroundStyle(Color.brand)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .foregroundStyle(Color.brand)
                }
            }
            .sheet(isPresented: $showProfilePreview) {
                NavigationStack {
                    ProfilePreviewView()
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterView()
            }
            .navigationDestination(item: $selectedProfileId) { id in
                ProfileView(profileId: id, onOpenChat: { selectedChatId = id }, onMatch: { _ in onMatch?() })
            }
            .navigationDestination(item: $selectedChatId) { id in
                ChatView(otherId: id)
            }
        }
        .task {
            await viewModel.load(userId: auth.user?.id ?? "")
        }
        .onAppear {
            if let userId = auth.user?.id { Task { await auth.fetchProfile(userId: userId) } }
        }
    }
    
    @ViewBuilder
    private var profileAvatar: some View {
        Button {
            onProfileTap?()
        } label: {
            Group {
                if let urlString = auth.profile?.primaryPhoto, let url = URL(string: urlString), !urlString.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure, .empty:
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.textMuted)
                        @unknown default:
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.textMuted)
                        }
                    }
                    .id("\(urlString)-\(profileRefreshTrigger.uuidString)")
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.textMuted)
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct EmptyDiscoverView: View {
    let onAdjustFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 64))
                .foregroundStyle(Color.textMuted)
            Text("No matches yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textOnDark)
            Text("Try adjusting your filters to see more people.")
                .font(.subheadline)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
