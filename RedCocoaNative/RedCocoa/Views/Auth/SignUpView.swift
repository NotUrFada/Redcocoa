import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var loading = false
    @State private var showTitle = false
    @State private var showForm = false
    @State private var showDivider = false
    @State private var showSocial = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Create your account")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textOnDark)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 24)
                
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
                }
                .padding(.horizontal)
                .opacity(showForm ? 1 : 0)
                .offset(y: showForm ? 0 : 24)
                
                Text("or")
                    .font(.subheadline)
                    .foregroundStyle(Color.textMuted)
                    .opacity(showDivider ? 1 : 0)
                    .offset(y: showDivider ? 0 : 20)
                    
                VStack(spacing: 12) {
                    Button {
                        Task {
                            error = nil
                            loading = true
                            do {
                                try await auth.signInWithApple()
                                loading = false
                                dismiss()
                            } catch {
                                self.error = AuthManager.friendlyAppleSignInError(error)
                                loading = false
                            }
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
                                loading = false
                                dismiss()
                            } catch {
                                self.error = error.localizedDescription
                                loading = false
                            }
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
                .padding(.horizontal)
                .opacity(showSocial ? 1 : 0)
                .offset(y: showSocial ? 0 : 24)
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgDark)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { showTitle = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.5)) { showForm = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.5)) { showDivider = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.easeOut(duration: 0.5)) { showSocial = true }
            }
        }
    }
    
    private func signUp() async {
        error = nil
        loading = true
        do {
            try await auth.signUp(email: email, password: password, name: name)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
