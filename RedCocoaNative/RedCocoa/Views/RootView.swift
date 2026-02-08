import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthManager
    @AppStorage("RedCocoa.v2.hasSeenWelcome") private var hasSeenWelcome = false
    @State private var splashFinished = false
    
    var body: some View {
        ZStack {
            if hasSeenWelcome {
                mainContent
            } else {
                ZStack {
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
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if auth.loading {
            LoadingView()
        } else if auth.user == nil {
            LoginView(onBackToWelcome: { hasSeenWelcome = false })
        } else if !auth.onboardingComplete {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.bgDark
                .ignoresSafeArea()
            ProgressView()
                .tint(Color.textOnDark)
        }
    }
}
