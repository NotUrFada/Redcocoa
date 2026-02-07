import SwiftUI

struct MatchOverlayView: View {
    let matchedName: String
    let onDismiss: () -> Void
    
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece, screenHeight: geo.size.height)
                }
                
                VStack(spacing: 24) {
                Text("It's a match!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("You and \(matchedName) liked each other")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                
                Button("Send message") {
                    onDismiss()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.brand)
                .cornerRadius(24)
                .padding(.top, 16)
            }
                .scaleEffect(scale)
                .opacity(opacity)
            }
            .onAppear {
                SoundEffectService.playMatch()
                spawnConfetti()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    scale = 1
                    opacity = 1
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func spawnConfetti() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .pink, .purple, Color.brand]
        confettiPieces = (0..<80).map { i in
            ConfettiPiece(
                id: i,
                x: CGFloat.random(in: 0...1),
                color: colors.randomElement() ?? .white,
                delay: Double.random(in: 0...0.5),
                duration: Double.random(in: 2...3.5),
                rotation: Double.random(in: 0...360),
                size: CGFloat.random(in: 6...14)
            )
        }
    }
}

private struct ConfettiPiece: Identifiable {
    let id: Int
    let x: CGFloat
    let color: Color
    let delay: Double
    let duration: Double
    let rotation: Double
    let size: CGFloat
}

private struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let screenHeight: CGFloat
    
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 0.6)
            .rotationEffect(.degrees(piece.rotation))
            .position(
                x: UIScreen.main.bounds.width * piece.x,
                y: -20 + offsetY
            )
            .onAppear {
                withAnimation(
                    .easeIn(duration: piece.duration)
                    .delay(piece.delay)
                ) {
                    offsetY = screenHeight + 100
                }
            }
    }
}
