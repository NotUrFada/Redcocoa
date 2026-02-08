import SwiftUI
import AVFoundation

struct VoiceMessagePlayer: View {
    let url: URL
    let isSent: Bool
    @State private var isPlaying = false
    @State private var duration: TimeInterval = 0
    @State private var currentTime: TimeInterval = 0
    @State private var player: AVPlayer?
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 12) {
            if isSent { Spacer(minLength: 40) }
            
            Button {
                togglePlayback()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(isSent ? .white : Color.brand)
                    
                    VStack(alignment: isSent ? .trailing : .leading, spacing: 4) {
                        Text(formatTime(isPlaying ? currentTime : duration))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(isSent ? .white.opacity(0.9) : Color.textOnDark)
                        Text("Voice message")
                            .font(.caption2)
                            .foregroundStyle(isSent ? .white.opacity(0.7) : Color.textMuted)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isSent ? Color.brand : Color.bgCard)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .onAppear {
                if player == nil {
                    setupPlayer()
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
                player?.pause()
            }
            
            if !isSent { Spacer(minLength: 40) }
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
    
    private func setupPlayer() {
        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        player = p
        
        Task {
            let dur = try? await item.asset.load(.duration)
            await MainActor.run {
                duration = dur?.seconds ?? 0
            }
        }
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in
            timer?.invalidate()
            timer = nil
            isPlaying = false
            currentTime = 0
            p.seek(to: .zero)
        }
    }
    
    private func togglePlayback() {
        guard let p = player else { return }
        if isPlaying {
            p.pause()
            timer?.invalidate()
            timer = nil
        } else {
            p.play()
            if duration == 0, let item = p.currentItem {
                Task {
                    let dur = try? await item.asset.load(.duration)
                    await MainActor.run {
                        duration = dur?.seconds ?? 0
                    }
                }
            }
            let t = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                currentTime = p.currentTime().seconds
            }
            RunLoop.main.add(t, forMode: .common)
            timer = t
        }
        isPlaying.toggle()
    }
}
