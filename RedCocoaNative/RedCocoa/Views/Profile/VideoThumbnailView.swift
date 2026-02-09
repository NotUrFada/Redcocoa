import SwiftUI
import AVKit
import AVFoundation

struct VideoThumbnailView: View {
    let url: String
    var autoplayAndLoop: Bool = true
    
    var body: some View {
        Group {
            if let videoURL = URL(string: url) {
                RemoteLoopingVideoPlayerView(url: videoURL)
            } else {
                ZStack {
                    Color.bgCard
                    Image(systemName: "video.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.textMuted)
                }
            }
        }
    }
}

private struct RemoteLoopingVideoPlayerView: View {
    let url: URL
    
    var body: some View {
        RemoteLoopingVideoPlayerRepresentable(url: url)
    }
}

private struct RemoteLoopingVideoPlayerRepresentable: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: url)
        player.isMuted = true
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = false
        vc.videoGravity = .resizeAspectFill
        context.coordinator.observer = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { _ in
            if player.currentItem?.duration.seconds.isFinite == true,
               player.currentTime().seconds >= (player.currentItem?.duration.seconds ?? 0) - 0.1 {
                player.seek(to: .zero)
                player.play()
            }
        }
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        player.play()
        return vc
    }
    
    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var observer: Any?
    }
}
