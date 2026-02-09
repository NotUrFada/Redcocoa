import SwiftUI
import UIKit

extension Notification.Name {
    static let chatsDidUpdate = Notification.Name("chatsDidUpdate")
    static let profileDidUpdate = Notification.Name("profileDidUpdate")
    static let openChatFromMatch = Notification.Name("openChatFromMatch")
}

struct MainTabView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var selectedTab = 0
    @State private var chatsRefreshTrigger = UUID()
    @State private var discoverProfileRefreshTrigger = UUID()
    @State private var openChatId: String?
    @State private var unreadMessageCount = 0
    @State private var likesCount = 0
    @State private var likesRefreshTrigger = UUID()
    @State private var globalIncomingCall: CallInvite?
    @State private var globalCallerProfile: Profile?
    @State private var showGlobalInCallView = false
    @State private var globalCallIsVideo = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView(
                profileRefreshTrigger: discoverProfileRefreshTrigger,
                onProfileTap: { selectedTab = 3 },
                onMatch: {
                    chatsRefreshTrigger = UUID()
                    likesRefreshTrigger = UUID()
                }
            )
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("Discover")
                }
                .tag(0)
            
            LikesView(refreshTrigger: likesRefreshTrigger, onLikesCountChanged: { likesCount = $0 })
                .smoothAppear()
                .tabItem {
                    Image(systemName: "heart")
                    Text("Likes")
                }
                .badge(likesCount)
                .tag(1)
            
            ChatsListView(selectedTab: selectedTab, refreshTrigger: chatsRefreshTrigger, openChatId: $openChatId, onUnreadCountChanged: { unreadMessageCount = $0 })
                .smoothAppear()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Chats")
                }
                .badge(unreadMessageCount)
                .tag(2)
            
            SettingsView()
                .smoothAppear()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(3)
        }
        .tint(.brand)
        .background(Color.bgDark)
        .onChange(of: selectedTab) { _, new in
            if new == 2 { chatsRefreshTrigger = UUID() }
            if new == 1 { likesRefreshTrigger = UUID() }
            if new == 0 {
                if let userId = auth.user?.id {
                    Task {
                        await auth.fetchProfile(userId: userId)
                        discoverProfileRefreshTrigger = UUID()
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .chatsDidUpdate)) { _ in
            chatsRefreshTrigger = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileDidUpdate)) { _ in
            likesRefreshTrigger = UUID()
            chatsRefreshTrigger = UUID()
            if let userId = auth.user?.id {
                Task {
                    await auth.fetchProfile(userId: userId)
                    discoverProfileRefreshTrigger = UUID()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openChatFromMatch)) { notification in
            if let otherId = notification.object as? String {
                selectedTab = 2
                chatsRefreshTrigger = UUID()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    openChatId = otherId
                }
            }
        }
        .onChange(of: unreadMessageCount) { _, _ in
            UIApplication.shared.applicationIconBadgeNumber = unreadMessageCount + likesCount
        }
        .onChange(of: likesCount) { _, _ in
            UIApplication.shared.applicationIconBadgeNumber = unreadMessageCount + likesCount
        }
        .onAppear {
            selectedTab = 0
            UIApplication.shared.applicationIconBadgeNumber = unreadMessageCount + likesCount
        }
        .task(id: auth.user?.id) {
            guard let userId = auth.user?.id else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard let invite = try? await APIService.getMyRingingCalls(calleeId: userId) else { continue }
                await MainActor.run {
                    if globalIncomingCall?.id != invite.id {
                        globalIncomingCall = invite
                        SoundEffectService.startCallRinging()
                        Task {
                            let profile = try? await APIService.getProfileById(invite.callerId, userId: userId)
                            await MainActor.run {
                                globalCallerProfile = profile
                            }
                        }
                        NotificationService.shared.scheduleIncomingCallNotification(callerName: globalCallerProfile?.name ?? "Someone")
                    }
                }
            }
        }
        .onChange(of: globalIncomingCall) { _, new in
            if new == nil {
                SoundEffectService.stopCallRinging()
                NotificationService.shared.cancelIncomingCallNotification()
            }
        }
        .fullScreenCover(item: $globalIncomingCall) { invite in
            globalIncomingCallView(invite: invite)
        }
        .fullScreenCover(isPresented: $showGlobalInCallView) {
            InCallView(
                otherName: globalCallerProfile?.name ?? "Match",
                otherPhotoUrl: globalCallerProfile?.primaryPhoto,
                isVideo: globalCallIsVideo
            ) {
                showGlobalInCallView = false
                globalCallerProfile = nil
            }
        }
    }

    @ViewBuilder
    private func globalIncomingCallView(invite: CallInvite) -> some View {
        ZStack {
            Color.bgDark.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Text("Incoming Call")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textMuted)
                if let urlStr = globalCallerProfile?.primaryPhoto, !urlStr.isEmpty, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Circle().fill(Color.bgCard).overlay { Image(systemName: "person.fill").font(.system(size: 60)).foregroundStyle(Color.textMuted) }
                        }
                    }
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.brand.opacity(0.5), lineWidth: 3))
                } else {
                    Circle()
                        .fill(Color.bgCard)
                        .frame(width: 140, height: 140)
                        .overlay { Image(systemName: "person.fill").font(.system(size: 60)).foregroundStyle(Color.textMuted) }
                        .overlay(Circle().stroke(Color.brand.opacity(0.5), lineWidth: 3))
                }
                VStack(spacing: 6) {
                    Text(globalCallerProfile?.name ?? "Match")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textOnDark)
                    Text(invite.callType == "video" ? "Video Call" : "Voice Call")
                        .font(.subheadline)
                        .foregroundStyle(Color.textMuted)
                }
                Spacer()
                HStack(spacing: 56) {
                    Button {
                        Task { await globalDeclineCall(invite) }
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "phone.down.fill")
                                .font(.system(size: 32))
                            Text("Decline")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 76, height: 76)
                        .background(Color.red.gradient, in: Circle())
                    }
                    .buttonStyle(.plain)
                    Button {
                        Task { await globalAnswerCall(invite) }
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 32))
                            Text("Answer")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 76, height: 76)
                        .background(Color.green.gradient, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 56)
            }
        }
    }

    private func globalAnswerCall(_ invite: CallInvite) async {
        NotificationService.shared.cancelIncomingCallNotification()
        SoundEffectService.stopCallRinging()
        do {
            globalCallIsVideo = invite.callType == "video"
            let uid = UInt((auth.user?.id.hashValue ?? 0) & 0x7FFFFFFF)
            try await CallService.shared.joinChannel(invite.channelName, uid: uid, isVideo: globalCallIsVideo)
            try? await APIService.updateCallStatus(inviteId: invite.id, status: "active")
            await MainActor.run {
                globalIncomingCall = nil
                showGlobalInCallView = true
            }
        } catch {
            await MainActor.run { globalIncomingCall = nil }
        }
    }

    private func globalDeclineCall(_ invite: CallInvite) async {
        SoundEffectService.stopCallRinging()
        NotificationService.shared.cancelIncomingCallNotification()
        try? await APIService.updateCallStatus(inviteId: invite.id, status: "missed")
        await MainActor.run { globalIncomingCall = nil }
    }
}
