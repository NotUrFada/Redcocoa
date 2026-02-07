import SwiftUI

extension Notification.Name {
    static let chatsDidUpdate = Notification.Name("chatsDidUpdate")
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var chatsRefreshTrigger = UUID()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView(onProfileTap: { selectedTab = 3 }, onMatch: { chatsRefreshTrigger = UUID() })
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
        }
        .onReceive(NotificationCenter.default.publisher(for: .chatsDidUpdate)) { _ in
            chatsRefreshTrigger = UUID()
        }
    }
}
