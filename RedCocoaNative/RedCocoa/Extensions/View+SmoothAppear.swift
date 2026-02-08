import SwiftUI

// MARK: - Smooth in-appear animation modifier
private struct SmoothAppearModifier: ViewModifier {
    let delay: Double
    let offset: CGFloat
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : offset)
            .onAppear {
                if delay > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.easeOut(duration: 0.4)) { appeared = true }
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.4)) { appeared = true }
                }
            }
    }
}

extension View {
    /// Smooth fade-in with optional upward slide. Use for screen content.
    func smoothAppear(delay: Double = 0, offset: CGFloat = 24) -> some View {
        modifier(SmoothAppearModifier(delay: delay, offset: offset))
    }
}
