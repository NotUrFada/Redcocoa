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
            UIApplication.shared.applicationIconBadgeNumber = unreadMessageCount + likesCount
        }
    }
}
