import SwiftUI
import UIKit

@main
struct RedCocoaApp: App {
    @StateObject private var auth = AuthManager.shared
    
    init() {
        // Tab bar brown theme
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(red: 30/255, green: 22/255, blue: 17/255, alpha: 1)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .preferredColorScheme(.dark)
                .tint(.brand)
                .onOpenURL { url in
                    auth.handleAuthURL(url)
                }
        }
    }
}
