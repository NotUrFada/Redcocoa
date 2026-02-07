import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView()
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
            
            ChatsListView()
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
    }
}
