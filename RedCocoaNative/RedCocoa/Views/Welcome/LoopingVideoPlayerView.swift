import SwiftUI
import AVKit
import AVFoundation

struct LoopingVideoPlayerView: UIViewRepresentable {
    let videoName: String
    let fileExtension: String
    
    init(videoName: String = "WelcomeVideo", fileExtension: String = "mp4") {
        self.videoName = videoName
        self.fileExtension = fileExtension
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView()
        if let url = Bundle.main.url(forResource: videoName, withExtension: fileExtension) {
            view.configure(url: url)
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

private final class PlayerUIView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var loopObserver: NSObjectProtocol?
    private var didBecomeActiveObserver: NSObjectProtocol?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        loopObserver.map { NotificationCenter.default.removeObserver($0) }
        didBecomeActiveObserver.map { NotificationCenter.default.removeObserver($0) }
    }
    
    func configure(url: URL) {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        
        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        avPlayer.isMuted = true
        avPlayer.automaticallyWaitsToMinimizeStalling = false
        
        let layer = AVPlayerLayer(player: avPlayer)
        layer.videoGravity = .resizeAspectFill
        self.layer.insertSublayer(layer, at: 0)
        
        player = avPlayer
        playerLayer = layer
        
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        
        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.player?.play()
        }
        
        avPlayer.play()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}
