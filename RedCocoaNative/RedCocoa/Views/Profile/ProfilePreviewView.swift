import SwiftUI

/// Preview of how the user's profile appears to others on the discovery page.
struct ProfilePreviewView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthManager
    
    var body: some View {
        ZStack {
            Color.bgDark
                .ignoresSafeArea()
            
            if let profile = auth.profile {
                VStack(spacing: 20) {
                    Text("How others see you")
                        .font(.headline)
                        .foregroundStyle(Color.textMuted)
                        .padding(.top, 8)
                    
                    ProfileCardView(profile: profile)
                        .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.brand)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.textMuted)
                    Text("Complete your profile to preview")
                        .font(.subheadline)
                        .foregroundStyle(Color.textMuted)
                        .multilineTextAlignment(.center)
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.brand)
                }
                .padding()
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(Color.brand)
            }
        }
        .task {
            if let userId = auth.user?.id {
                await auth.fetchProfile(userId: userId)
            }
        }
    }
}
