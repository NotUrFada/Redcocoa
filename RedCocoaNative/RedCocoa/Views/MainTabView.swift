import SwiftUI

extension Notification.Name {
    static let chatsDidUpdate = Notification.Name("chatsDidUpdate")
    static let profileDidUpdate = Notification.Name("profileDidUpdate")
}

struct MainTabView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var selectedTab = 0
    @State private var chatsRefreshTrigger = UUID()
    @State private var discoverProfileRefreshTrigger = UUID()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView(
                profileRefreshTrigger: discoverProfileRefreshTrigger,
                onProfileTap: { selectedTab = 3 },
                onMatch: { chatsRefreshTrigger = UUID() }
            )
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("Discover")
                }
                .tag(0)
            
            LikesView()
                .tabItem {
                    Image(systemName: "heart")
                    Text("Likes")
                }
                .tag(1)
            
            ChatsListView(selectedTab: selectedTab, refreshTrigger: chatsRefreshTrigger)
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Chats")
                }
                .tag(2)
            
            SettingsView()
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
            if new == 0 {
                discoverProfileRefreshTrigger = UUID()
                if let userId = auth.user?.id {
                    Task { await auth.fetchProfile(userId: userId) }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .chatsDidUpdate)) { _ in
            chatsRefreshTrigger = UUID()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profileDidUpdate)) { _ in
            discoverProfileRefreshTrigger = UUID()
            if let userId = auth.user?.id {
                Task { await auth.fetchProfile(userId: userId) }
            }
        }
    }
}
