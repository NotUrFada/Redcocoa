import Foundation
import Supabase
import Combine
import AuthenticationServices
import CryptoKit

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var user: AppUser?
    @Published var profile: Profile?
    @Published var loading = true
    @Published var onboardingComplete = false
    
    private var supabase: SupabaseClient? { SupabaseConfig.client }
    
    private init() {
        Task { await checkSession() }
    }
    
    func checkSession() async {
        guard let supabase = supabase else {
            user = AppUser(id: "demo", email: "demo@redcocoa.app")
            profile = Profile(id: "demo", name: "Demo User")
            loading = false
            onboardingComplete = true
            return
        }
        
        do {
            let session = try await supabase.auth.session
            user = AppUser(id: session.user.id.uuidString, email: session.user.email ?? "")
            await fetchProfile(userId: session.user.id.uuidString)
            onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
        } catch {
            user = nil
            profile = nil
        }
        loading = false
    }
    
    func signIn(email: String, password: String) async throws {
        guard let supabase = supabase else {
            user = AppUser(id: "demo", email: email)
            profile = Profile(id: "demo", name: email.components(separatedBy: "@").first ?? "User")
            onboardingComplete = true
            return
        }
        
        _ = try await supabase.auth.signIn(email: email, password: password)
        await checkSession()
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        guard let supabase = supabase else {
            user = AppUser(id: "demo", email: email)
            profile = Profile(id: "demo", name: name.isEmpty ? email.components(separatedBy: "@").first ?? "User" : name)
            return
        }
        
        _ = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: ["name": .string(name)]
        )
        await checkSession()
    }
    
    func signOut() async {
        if let supabase = supabase {
            _ = try? await supabase.auth.signOut()
        }
        user = nil
        profile = nil
        onboardingComplete = false
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
    }
    
    func deleteAccount() async throws {
        guard let supabase = supabase else {
            user = nil
            profile = nil
            onboardingComplete = false
            UserDefaults.standard.removeObject(forKey: "onboardingComplete")
            return
        }
        let session = try await supabase.auth.session
        guard let url = URL(string: Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Supabase URL"])
        }
        components.path = "/auth/v1/user"
        guard let deleteURL = components.url else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: deleteURL)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? "", forHTTPHeaderField: "apikey")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to delete account"])
        }
        try await supabase.auth.signOut()
        user = nil
        profile = nil
        onboardingComplete = false
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
    }
    
    func resetPassword(email: String) async throws {
        guard let supabase = supabase else { return }
        try await supabase.auth.resetPasswordForEmail(email)
    }
    
    // MARK: - Sign in with Apple
    func signInWithApple() async throws {
        guard let supabase = supabase else {
            user = AppUser(id: "demo", email: "demo@redcocoa.app")
            profile = Profile(id: "demo", name: "Demo User")
            onboardingComplete = true
            return
        }
        let nonce = randomNonceString()
        let hashedNonce = sha256(nonce)
        let req = ASAuthorizationAppleIDProvider().createRequest()
        req.requestedScopes = [.fullName, .email]
        req.nonce = hashedNonce
        let controller = ASAuthorizationController(authorizationRequests: [req])
        let delegate = AppleSignInDelegate(nonce: nonce)
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
        let cred = try await delegate.result
        guard let tokenData = cred.identityToken, let idToken = String(data: tokenData, encoding: .utf8) else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Apple ID token"])
        }
        _ = try await supabase.auth.signInWithIdToken(credentials: OpenIDConnectCredentials(
            provider: .apple,
            idToken: idToken,
            nonce: nonce
        ))
        if let fullName = cred.fullName {
            let name = [fullName.givenName, fullName.familyName].compactMap { $0 }.joined(separator: " ")
            if !name.isEmpty {
                _ = try? await supabase.auth.update(user: UserAttributes(data: [
                    "full_name": .string(name),
                    "given_name": .string(fullName.givenName ?? ""),
                    "family_name": .string(fullName.familyName ?? "")
                ]))
            }
        }
        await checkSession()
    }
    
    // MARK: - Sign in with Google (OAuth)
    func signInWithGoogle() async throws {
        guard let supabase = supabase else {
            user = AppUser(id: "demo", email: "demo@redcocoa.app")
            profile = Profile(id: "demo", name: "Demo User")
            onboardingComplete = true
            return
        }
        let redirectURL = URL(string: "com.redcocoa.app://auth/callback")!
        _ = try await supabase.auth.signInWithOAuth(provider: .google, redirectTo: redirectURL)
        await checkSession()
    }
    
    func handleAuthURL(_ url: URL) {
        Task { @MainActor in
            _ = supabase?.auth.handle(url)
            await checkSession()
        }
    }
    
    // MARK: - Sign in with phone
    func signInWithPhone(_ phone: String) async throws {
        guard let supabase = supabase else { return }
        let normalized = phone.hasPrefix("+") ? phone : "+1\(phone.filter { $0.isNumber })"
        try await supabase.auth.signInWithOTP(phone: normalized)
    }
    
    func verifyPhoneOTP(phone: String, token: String) async throws {
        guard let supabase = supabase else {
            user = AppUser(id: "demo", email: "demo@redcocoa.app")
            profile = Profile(id: "demo", name: "Demo User")
            onboardingComplete = true
            return
        }
        let normalized = phone.hasPrefix("+") ? phone : "+1\(phone.filter { $0.isNumber })"
        _ = try await supabase.auth.verifyOTP(phone: normalized, token: token, type: .sms)
        await checkSession()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess { fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)") }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    func fetchProfile(userId: String) async {
        guard let supabase = supabase else { return }
        
        do {
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            self.profile = profile
        } catch {
            print("Profile fetch error: \(error)")
        }
    }
    
    func completeOnboarding() {
        onboardingComplete = true
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
    }
}
