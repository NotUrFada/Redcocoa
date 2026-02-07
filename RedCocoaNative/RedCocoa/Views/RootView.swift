import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthManager
    @AppStorage("RedCocoa.v2.hasSeenWelcome") private var hasSeenWelcome = false
    @State private var splashFinished = false
    
    var body: some View {
        Group {
            if !splashFinished {
                SplashView()
            } else if !hasSeenWelcome {
                WelcomeView(onGetStarted: {
                    hasSeenWelcome = true
                })
            } else if auth.loading {
                LoadingView()
            } else if auth.user == nil {
                LoginView()
            } else if !auth.onboardingComplete {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .background(Color.bgDark)
        .animation(.easeInOut(duration: 0.3), value: splashFinished)
        .animation(.easeInOut(duration: 0.3), value: hasSeenWelcome)
        .task(id: splashFinished) {
            guard !splashFinished else { return }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            splashFinished = true
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
