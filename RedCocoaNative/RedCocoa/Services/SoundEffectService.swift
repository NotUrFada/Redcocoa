import UIKit
import AudioToolbox

/// Plays sound effects for swipe actions, button taps, and match celebration.
enum SoundEffectService {
    
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
    
    private static func play(systemSoundID: SystemSoundID) {
        AudioServicesPlaySystemSound(systemSoundID)
    }
}
