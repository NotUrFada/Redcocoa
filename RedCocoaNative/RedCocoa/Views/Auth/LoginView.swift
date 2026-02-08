import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthManager
    var onBackToWelcome: (() -> Void)? = nil
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var loading = false
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 40)
                    
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 56, height: 56)
                    
                    Text("Red Cocoa")
                        .font(.interThin(size: 28))
                        .foregroundStyle(Color.textOnDark)
                    
                    Text("Find your perfect match")
                        .font(.subheadline)
                        .foregroundStyle(Color.textMuted)
                    
                    VStack(spacing: 16) {
                        if let error = error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.bgCard)
                            .cornerRadius(12)
                            .foregroundStyle(Color.textOnDark)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.bgCard)
                            .cornerRadius(12)
                            .foregroundStyle(Color.textOnDark)
                            .textContentType(.password)
                        
                        Button("Forgot password?") {
                            showForgotPassword = true
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.brand)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        Button {
                            Task { await signIn() }
                        } label: {
                            if loading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brand)
                        .foregroundStyle(.white)
                        .cornerRadius(24)
                        .fontWeight(.semibold)
                        .disabled(loading || email.isEmpty || password.isEmpty)
                    }
                    .padding(.horizontal)
                    
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
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Don't have an account?")
                            .foregroundStyle(Color.textMuted)
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .foregroundStyle(Color.brand)
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    
                    Spacer().frame(height: 40)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgDark)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if let onBack = onBackToWelcome {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            onBack()
                        } label: {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(Color.brand)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 40)
                    .onEnded { value in
                        guard let onBack = onBackToWelcome else { return }
                        let fromLeftEdge = value.startLocation.x < 60
                        let rightSwipe = value.translation.width > 60
                        let mostlyHorizontal = abs(value.translation.height) < abs(value.translation.width) * 1.5
                        if fromLeftEdge && rightSwipe && mostlyHorizontal {
                            onBack()
                        }
                    }
            )
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
    
    private func signIn() async {
        error = nil
        loading = true
        do {
            try await auth.signIn(email: email, password: password)
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
