import SwiftUI

/// First-open welcome screen with background image.
struct WelcomeView: View {
    var onGetStarted: () -> Void
    
    @State private var showDating = false
    @State private var showTagline = false
    @State private var showButton = false
    
    var body: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
            
            // Gradient overlay for readability (video is behind from RootView)
            LinearGradient(
                colors: [
                    Color.black.opacity(0.6),
                    Color.clear,
                    Color.black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                
                // Bottom content
                VStack(alignment: .leading, spacing: 12) {
                    // DATING 18+
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("DATING")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(Color.textOnDark)
                        Text("18+")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.brand)
                            .cornerRadius(20)
                    }
                    .opacity(showDating ? 1 : 0)
                    .offset(y: showDating ? 0 : 24)
                    
                    Text("EVERY MINUTE THERE ARE MORE THAN 300 NEW MATCHES IN THE APP")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textOnDark.opacity(0.95))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(showTagline ? 1 : 0)
                        .offset(y: showTagline ? 0 : 20)
                    
                    Button(action: onGetStarted) {
                        Text("GET STARTED")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.brand)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .opacity(showButton ? 1 : 0)
                    .offset(y: showButton ? 0 : 20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) { showDating = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.5)) { showTagline = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    withAnimation(.easeOut(duration: 0.5)) { showButton = true }
                }
            }
        }
    }
}
