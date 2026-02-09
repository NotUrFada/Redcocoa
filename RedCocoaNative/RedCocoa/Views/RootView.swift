import SwiftUI
import UIKit

struct RootView: View {
    @EnvironmentObject var auth: AuthManager
    @AppStorage("RedCocoa.v2.hasSeenWelcome") private var hasSeenWelcome = false
    @State private var splashFinished = false
    @State private var mainTabViewKey = 0
    
    var body: some View {
        ZStack {
            if hasSeenWelcome {
                mainContent
            } else {
                ZStack {
                    // Video starts playing immediately (during splash) so it's ready when user sees welcome
                    LoopingVideoPlayerView(videoName: "WelcomeVideo", fileExtension: "mp4")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                    
                    SplashView()
                        .opacity(splashFinished ? 0 : 1)
                        .allowsHitTesting(!splashFinished)
                    
                    WelcomeView(onGetStarted: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            hasSeenWelcome = true
                        }
                    })
                    .opacity(splashFinished ? 1 : 0)
                    .allowsHitTesting(splashFinished)
                }
                .animation(.easeInOut(duration: 0.4), value: splashFinished)
            }
        }
        .background(Color.bgDark)
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                splashFinished = true
            }
        }
        .onChange(of: auth.user) { _, new in
            if new == nil {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        Group {
            if auth.loading {
                LoadingView()
            } else if auth.user == nil {
                LoginView(onBackToWelcome: { hasSeenWelcome = false })
            } else if !auth.onboardingComplete {
                OnboardingView()
            } else {
                MainTabView()
                    .id(mainTabViewKey)
            }
        }
        .transition(.opacity)
        .animation(.easeOut(duration: 0.35), value: "\(auth.loading)_\(auth.user?.id ?? "nil")_\(auth.onboardingComplete)")
        .onChange(of: auth.user != nil && auth.onboardingComplete) { _, showingMainTab in
            if showingMainTab {
                mainTabViewKey += 1
            }
        }
    }
}

struct LoadingView: View {
    @State private var appeared = false
    var body: some View {
        ZStack {
            Color.bgDark
                .ignoresSafeArea()
            ProgressView()
                .tint(Color.textOnDark)
                .scaleEffect(appeared ? 1 : 0.9)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { appeared = true }
        }
    }
}
