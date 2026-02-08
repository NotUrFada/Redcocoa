import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var currentPage = 0
    @State private var showProfileSetup = false
    
    var body: some View {
        Group {
            if showProfileSetup {
                ProfileSetupView(onComplete: {
                    auth.completeOnboarding()
                })
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
            } else {
                onboardingSlides
            }
        }
        .animation(.easeOut(duration: 0.35), value: showProfileSetup)
        .background(Color.bgDark)
    }
    
    private var onboardingSlides: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    icon: "heart.circle",
                    title: "Welcome to Red Cocoa",
                    subtitle: "Find your perfect match. Swipe, connect, and start meaningful conversations.",
                    useLogo: true
                )
                .tag(0)
                
                OnboardingPage(
                    icon: "person.2",
                    title: "Discover People",
                    subtitle: "Browse profiles, like who interests you, and get matched when it's mutual.",
                    useLogo: false
                )
                .tag(1)
                
                OnboardingPage(
                    icon: "bubble.left.and.bubble.right",
                    title: "Start Chatting",
                    subtitle: "Once you match, start the conversation. Your perfect match is out there.",
                    useLogo: false
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            Spacer()
            
            Button {
                if currentPage < 2 {
                    withAnimation(.easeInOut(duration: 0.3)) { currentPage += 1 }
                } else {
                    withAnimation(.easeOut(duration: 0.35)) { showProfileSetup = true }
                }
            } label: {
                Text(currentPage < 2 ? "Continue" : "Set up profile")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brand)
                    .foregroundStyle(.white)
                    .cornerRadius(24)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let subtitle: String
    var useLogo: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            if useLogo {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundStyle(Color.brand)
            }
            Text(title)
                .font(title.contains("Red Cocoa") ? .interThin(size: 26) : .title.weight(.bold))
                .foregroundStyle(Color.textOnDark)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(Color.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
}
