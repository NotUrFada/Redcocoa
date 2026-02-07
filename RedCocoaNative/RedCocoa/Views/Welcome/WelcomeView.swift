import SwiftUI

/// First-open welcome screen with background image.
struct WelcomeView: View {
    var onGetStarted: () -> Void
    
    var body: some View {
        ZStack {
            Color.bgDark
                .ignoresSafeArea()
            Image("WelcomeBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // Gradient overlay for readability
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
                // Top left: logo + red cocoa
                HStack(spacing: 10) {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                    Text("red cocoa")
                        .font(.interThin(size: 24))
                        .foregroundStyle(Color.textOnDark)
                }
                .padding(.leading, 24)
                .padding(.top, 60)
                
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
                    
                    Text("EVERY MINUTE THERE ARE MORE THAN 300 NEW MATCHES IN THE APP")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textOnDark.opacity(0.95))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    
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
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}
