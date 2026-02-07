import SwiftUI

struct PhoneAuthView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var phone = ""
    @State private var otp = ""
    @State private var otpSent = false
    @State private var error: String?
    @State private var loading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(otpSent ? "Enter verification code" : "Sign in with phone")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textOnDark)
                
                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                if otpSent {
                    TextField("6-digit code", text: $otp)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.bgCard)
                        .cornerRadius(12)
                        .foregroundStyle(Color.textOnDark)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        Task { await verify() }
                    } label: {
                        if loading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Verify")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brand)
                    .foregroundStyle(.white)
                    .cornerRadius(24)
                    .fontWeight(.semibold)
                    .disabled(loading || otp.count != 6)
                    
                    Button("Use a different number") {
                        otpSent = false
                        otp = ""
                        error = nil
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.textMuted)
                } else {
                    TextField("+15551234567", text: $phone)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.bgCard)
                        .cornerRadius(12)
                        .foregroundStyle(Color.textOnDark)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    
                    Text("Use +1 for US (e.g. +15551234567). We'll send a 6-digit code via SMS.")
                        .font(.caption)
                        .foregroundStyle(Color.textMuted)
                    
                    Button {
                        Task { await sendOTP() }
                    } label: {
                        if loading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send code")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brand)
                    .foregroundStyle(.white)
                    .cornerRadius(24)
                    .fontWeight(.semibold)
                    .disabled(loading || phone.isEmpty)
                }
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgDark)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationTitle("Phone")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendOTP() async {
        error = nil
        loading = true
        do {
            try await auth.signInWithPhone(phone)
            otpSent = true
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
    
    private func verify() async {
        error = nil
        loading = true
        do {
            try await auth.verifyPhoneOTP(phone: phone, token: otp)
            auth.completeOnboarding()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
