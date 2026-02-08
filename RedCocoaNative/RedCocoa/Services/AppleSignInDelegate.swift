import AuthenticationServices

@MainActor
final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let nonce: String
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
    
    var result: ASAuthorizationAppleIDCredential {
        get async throws {
            try await withCheckedThrowingContinuation { cont in
                continuation = cont
            }
        }
    }
    
    init(nonce: String) {
        self.nonce = nonce
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = cred.identityToken,
              let _ = String(data: tokenData, encoding: .utf8) else {
            continuation?.resume(throwing: NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Apple credential"]))
            continuation = nil
            return
        }
        continuation?.resume(returning: cred)
        continuation = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            if let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                return keyWindow
            }
            if let window = windowScene.windows.first(where: { !$0.isHidden }) {
                return window
            }
            if let first = windowScene.windows.first {
                return first
            }
        }
        return UIWindow()
    }
}
