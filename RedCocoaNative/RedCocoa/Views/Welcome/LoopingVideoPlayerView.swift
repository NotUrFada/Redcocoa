import SwiftUI
import AVKit

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
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var looper: AVPlayerLooper?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(url: URL) {
        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true
        
        let layer = AVPlayerLayer(player: queuePlayer)
        layer.videoGravity = .resizeAspectFill
        self.layer.insertSublayer(layer, at: 0)
        
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        queuePlayer.play()
        
        player = queuePlayer
        playerLayer = layer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}
