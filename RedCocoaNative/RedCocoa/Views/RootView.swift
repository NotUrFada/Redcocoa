import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthManager
    @AppStorage("RedCocoa.hasSeenWelcome") private var hasSeenWelcome = false
    @State private var splashFinished = false
    
    var body: some View {
        Group {
            if !splashFinished {
                SplashView(onFinish: { splashFinished = true })
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
