import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var error: String?
    @State private var sent = false
    @State private var loading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if sent {
                    Text("Check your email")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textOnDark)
                    Text("We sent a password reset link to \(email)")
                        .font(.subheadline)
                        .foregroundStyle(Color.textMuted)
                        .multilineTextAlignment(.center)
                    Button("Back to Sign In") {
                        dismiss()
                    }
                    .foregroundStyle(Color.brand)
                } else {
                    Text("Forgot password")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textOnDark)
                    Text("Enter your email and we'll send you a reset link")
                        .font(.subheadline)
                        .foregroundStyle(Color.textMuted)
                    
                    VStack(spacing: 16) {
                        if let error = error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.bgCard)
                            .cornerRadius(12)
                            .foregroundStyle(Color.textOnDark)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                        
                        Button {
                            Task { await resetPassword() }
                        } label: {
                            if loading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send reset link")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brand)
                        .foregroundStyle(.white)
                        .cornerRadius(24)
                        .fontWeight(.semibold)
                        .disabled(loading || email.isEmpty)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgDark)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func resetPassword() async {
        error = nil
        loading = true
        do {
            try await auth.resetPassword(email: email)
            sent = true
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
