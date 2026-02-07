import SwiftUI

struct ProfileView: View {
    let profileId: String
    var onOpenChat: (() -> Void)?
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var profile: Profile?
    @State private var loading = true
    @State private var showReportMenu = false
    @State private var reportSent = false
    
    var body: some View {
        Group {
            if loading {
                ProgressView()
                    .tint(Color.textOnDark)
            } else if let p = profile {
                profileContent(p)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                }
            }
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
    }
    
    @ViewBuilder
    private func profileContent(_ p: Profile) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: p.primaryPhoto ?? "")) { phase in
                    switch phase {
                    case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                    default: Rectangle().fill(Color.gray.opacity(0.2)).overlay { Image(systemName: "person.circle").font(.largeTitle) }
                    }
                }
                .frame(height: 400)
                .clipped()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(p.name).font(.title2).fontWeight(.bold).foregroundStyle(Color.textOnDark)
                        if let age = p.displayAge {
                            Text("• \(age)").foregroundStyle(Color.textMuted)
                        }
                    }
                    if let loc = p.location { Text(loc).font(.subheadline).foregroundStyle(Color.textMuted) }
                    if let bio = p.bio { Text(bio).font(.body).foregroundStyle(Color.textOnDark).padding(.top, 4) }
                    if let responses = p.promptResponses, !responses.isEmpty {
                        ForEach(ProfileOptions.allPrompts.filter { responses[$0.id] != nil }, id: \.id) { prompt in
                            if let answer = responses[prompt.id], !answer.isEmpty {
                                Text(prompt.text.replacingOccurrences(of: "___", with: answer))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textMuted)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding()
                
                HStack(spacing: 16) {
                    Button { Task { await pass() } } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(Color.textOnDark)
                            .frame(width: 56, height: 56)
                            .background(Color.bgCard)
                            .clipShape(Circle())
                    }
                    Button { Task { await like() } } label: {
                        Image(systemName: "heart.fill")
                            .font(.title2)
                            .frame(width: 56, height: 56)
                            .background(Color.brand)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }
                    Button {
                        if let onOpenChat = onOpenChat { onOpenChat() }
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "bubble.left")
                            Text("Message")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.brand)
                        .foregroundStyle(.white)
                        .cornerRadius(24)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgDark)
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
        guard let userId = auth.user?.id else { return }
        let isMatch = (try? await APIService.likeProfile(userId: userId, likedId: profileId)) ?? false
        await MainActor.run {
            if isMatch { onOpenChat?() }
            dismiss()
        }
    }
    
    private func block() async {
        guard let userId = auth.user?.id else { return }
        try? await APIService.blockUser(blockerId: userId, blockedId: profileId)
        dismiss()
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
