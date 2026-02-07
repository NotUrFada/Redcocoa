import SwiftUI
import AVKit

struct VideoThumbnailView: View {
    let url: String
    
    var body: some View {
        Group {
            if let videoURL = URL(string: url) {
                VideoPlayer(player: AVPlayer(url: videoURL))
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
