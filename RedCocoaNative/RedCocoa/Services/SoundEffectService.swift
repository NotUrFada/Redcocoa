import UIKit
import AudioToolbox

/// Plays sound effects for swipe actions, button taps, match celebration, and incoming calls.
enum SoundEffectService {

    private static var callRingTimer: Timer?
    private static let callRingInterval: TimeInterval = 1.6

    /// Play when user passes (swipe left or pass button).
    static func playPass() {
        play(systemSoundID: 1104) // keyboard tap – subtle
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Play when user likes (swipe right or like button).
    static func playLike() {
        play(systemSoundID: 1007) // peek – satisfying pop
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Play when it's a match (confetti overlay).
    static func playMatch() {
        play(systemSoundID: 1025) // celebration
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Start incoming call ring: repeating sound + vibration until stopped.
    static func startCallRinging() {
        stopCallRinging()
        playCallRingOnce()
        callRingTimer = Timer.scheduledTimer(withTimeInterval: callRingInterval, repeats: true) { _ in
            playCallRingOnce()
        }
        RunLoop.main.add(callRingTimer!, forMode: .common)
    }

    /// Stop incoming call ring and vibration.
    static func stopCallRinging() {
        callRingTimer?.invalidate()
        callRingTimer = nil
    }

    private static func playCallRingOnce() {
        AudioServicesPlaySystemSound(1013) // SMS received – ring-like
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    private static func play(systemSoundID: SystemSoundID) {
        AudioServicesPlaySystemSound(systemSoundID)
    }
}
