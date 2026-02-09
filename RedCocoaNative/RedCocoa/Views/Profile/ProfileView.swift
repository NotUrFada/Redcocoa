import SwiftUI

struct ProfileView: View {
    let profileId: String
    var onOpenChat: (() -> Void)?
    var onMatch: ((Profile) -> Void)?
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var profile: Profile?
    @State private var loading = true
    @State private var showReportMenu = false
    @State private var reportSent = false
    @State private var showBlockError = false
    
    var body: some View {
        Group {
            if loading {
                Color.bgDark
                    .overlay { ProgressView().tint(Color.textOnDark) }
            } else if let p = profile {
                profileContent(p)
                    .smoothAppear()
            } else {
                ContentUnavailableView("Profile unavailable", systemImage: "person.circle")
                    .foregroundStyle(Color.textMuted)
                    .smoothAppear()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Report", role: .destructive) { showReportMenu = true }
                    Button("Block", role: .destructive) { Task { await block() } }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .task { await load() }
        .confirmationDialog("Report", isPresented: $showReportMenu) {
            Button("Spam") { report(reason: "spam") }
            Button("Inappropriate") { report(reason: "inappropriate") }
            Button("Other") { report(reason: "other") }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Could not block", isPresented: $showBlockError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again.")
        }
    }
    
    @ViewBuilder
    private func profileContent(_ p: Profile) -> some View {
        GeometryReader { geo in
            let photoHeight = geo.size.height * 0.78
            VStack(spacing: 0) {
                profileMediaSection(p, height: photoHeight)
                    .frame(height: photoHeight)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(p.name)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(Color.textOnDark)
                                if let age = p.displayAge {
                                    Text("·")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundStyle(Color.textMuted)
                                    Text("\(age)")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundStyle(Color.textMuted)
                                }
                            }
                            if let loc = p.location, !loc.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.caption)
                                    Text(loc)
                                        .font(.subheadline)
                                }
                                .foregroundStyle(Color.textMuted)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if let interests = p.interests, !interests.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(interests.prefix(6), id: \.self) { interest in
                                        Text(interest)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(Color.bgCard.opacity(0.9))
                                            .foregroundStyle(Color.textOnDark)
                                            .cornerRadius(18)
                                    }
                                }
                            }
                        }

                        if let bio = p.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.system(size: 16, weight: .regular))
                                .lineSpacing(6)
                                .foregroundStyle(Color.textOnDark.opacity(0.95))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let responses = p.promptResponses, !responses.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(ProfileOptions.allPrompts.filter { responses[$0.id] != nil }, id: \.id) { prompt in
                                    if let answer = responses[prompt.id], !answer.isEmpty {
                                        Text(prompt.text.replacingOccurrences(of: "___", with: answer))
                                            .font(.subheadline)
                                            .foregroundStyle(Color.textMuted)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 32)
                }
                .background(Color.bgDark)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.bgDark)
    }
    
    @ViewBuilder
    private func profileMediaSection(_ p: Profile, height: CGFloat) -> some View {
        let photos = p.photoUrls ?? []
        let videos = p.videoUrls ?? []
        if !photos.isEmpty || !videos.isEmpty {
            TabView {
                ForEach(Array(photos.enumerated()), id: \.element) { _, urlString in
                    ZStack {
                        AsyncImage(url: URL(string: urlString)) { phase in
                            switch phase {
                            case .success(let img):
                                img
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay { Image(systemName: "person.circle").font(.system(size: 80)) }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .overlay {
                            RadialGradient(
                                colors: [
                                    Color.clear,
                                    Color.black.opacity(0.05),
                                    Color.black.opacity(0.15),
                                    Color.black.opacity(0.35)
                                ],
                                center: .center,
                                startRadius: 80,
                                endRadius: 450
                            )
                        }
                        .overlay {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .clear, location: 0.42),
                                    .init(color: Color.bgDark.opacity(0.6), location: 0.58),
                                    .init(color: Color.bgDark, location: 0.72)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .overlay(alignment: .top) {
                            LinearGradient(
                                stops: [
                                    .init(color: Color.bgDark, location: 0),
                                    .init(color: Color.bgDark.opacity(0.8), location: 0.25),
                                    .init(color: Color.bgDark.opacity(0.3), location: 0.45),
                                    .init(color: .clear, location: 0.65)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 180)
                            .allowsHitTesting(false)
                        }
                    }
                }
                ForEach(Array(videos.enumerated()), id: \.element) { _, urlString in
                    ZStack {
                        VideoThumbnailView(url: urlString)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    }
                    .overlay {
                        RadialGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.05),
                                Color.black.opacity(0.15),
                                Color.black.opacity(0.35)
                            ],
                            center: .center,
                            startRadius: 80,
                            endRadius: 450
                        )
                    }
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .clear, location: 0.42),
                                .init(color: Color.bgDark.opacity(0.6), location: 0.58),
                                .init(color: Color.bgDark, location: 0.72)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .overlay(alignment: .top) {
                        LinearGradient(
                            stops: [
                                .init(color: Color.bgDark, location: 0),
                                .init(color: Color.bgDark.opacity(0.8), location: 0.25),
                                .init(color: Color.bgDark.opacity(0.3), location: 0.45),
                                .init(color: .clear, location: 0.65)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 180)
                        .allowsHitTesting(false)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay { Image(systemName: "person.circle").font(.system(size: 80)).foregroundStyle(Color.textMuted) }
        }
    }
    
    private func load() async {
        do {
            profile = try await APIService.getProfileById(profileId, userId: auth.user?.id)
        } catch {
            profile = MockData.profiles.first { $0.id == profileId } ?? MockData.profiles.first
        }
        loading = false
    }
    
    private func pass() async {
        guard let userId = auth.user?.id else { return }
        try? await APIService.passOnProfile(userId: userId, passedId: profileId)
        dismiss()
    }
    
    private func like() async {
        guard let userId = auth.user?.id,
              let p = profile else { return }
        let isMatch = (try? await APIService.likeProfile(userId: userId, likedId: profileId)) ?? false
        await MainActor.run {
            if isMatch {
                if let onMatch = onMatch {
                    onMatch(p)
                    dismiss()
                } else {
                    onOpenChat?()
                    dismiss()
                }
            } else {
                dismiss()
            }
        }
    }
    
    private func block() async {
        guard let userId = auth.user?.id else { return }
        do {
            try await APIService.blockUser(blockerId: userId, blockedId: profileId)
            NotificationCenter.default.post(name: .profileDidUpdate, object: nil)
            await MainActor.run { dismiss() }
        } catch {
            await MainActor.run { showBlockError = true }
        }
    }
    
    private func report(reason: String) {
        Task {
            guard let userId = auth.user?.id else { return }
            try? await APIService.reportUser(reporterId: userId, reportedId: profileId, reason: reason)
            reportSent = true
            showReportMenu = false
        }
    }
    
}
