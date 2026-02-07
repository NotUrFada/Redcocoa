import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var loading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Create your account")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textOnDark)
                
                VStack(spacing: 16) {
                    if let error = error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    TextField("Name", text: $name)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.bgCard)
                        .cornerRadius(12)
                        .foregroundStyle(Color.textOnDark)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.bgCard)
                        .cornerRadius(12)
                        .foregroundStyle(Color.textOnDark)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password (min 6 characters)", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.bgCard)
                        .cornerRadius(12)
                        .foregroundStyle(Color.textOnDark)
                        .textContentType(.newPassword)
                    
                    Button {
                        Task { await signUp() }
                    } label: {
                        if loading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign Up")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brand)
                    .foregroundStyle(.white)
                    .cornerRadius(24)
                    .fontWeight(.semibold)
                    .disabled(loading || email.isEmpty || password.isEmpty || password.count < 6)
                    
                    Text("or")
                        .font(.subheadline)
                        .foregroundStyle(Color.textMuted)
                    
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                error = nil
                                loading = true
                                do {
                                    try await auth.signInWithApple()
                                    auth.completeOnboarding()
                                    dismiss()
                                } catch {
                                    self.error = error.localizedDescription
                                }
                                loading = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: "apple.logo")
                                Text("Continue with Apple")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundStyle(.black)
                            .cornerRadius(12)
                            .fontWeight(.medium)
                        }
                        .buttonStyle(.plain)
                        .disabled(loading)
                        
                        Button {
                            Task {
                                error = nil
                                loading = true
                                do {
                                    try await auth.signInWithGoogle()
                                    auth.completeOnboarding()
                                    dismiss()
                                } catch {
                                    self.error = error.localizedDescription
                                }
                                loading = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                Text("Continue with Google")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.bgCard)
                            .foregroundStyle(Color.textOnDark)
                            .cornerRadius(12)
                            .fontWeight(.medium)
                        }
                        .buttonStyle(.plain)
                        .disabled(loading)
                        
                        NavigationLink(destination: PhoneAuthView()) {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("Continue with phone")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.bgCard)
                            .foregroundStyle(Color.textOnDark)
                            .cornerRadius(12)
                            .fontWeight(.medium)
                        }
                        .buttonStyle(.plain)
                        .disabled(loading)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgDark)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func signUp() async {
        error = nil
        loading = true
        do {
            try await auth.signUp(email: email, password: password, name: name)
            auth.completeOnboarding()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
