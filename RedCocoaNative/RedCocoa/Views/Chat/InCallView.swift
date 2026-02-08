import SwiftUI
import AgoraRtcKit

/// Full-screen in-app voice or video call UI.
struct InCallView: View {
    let otherName: String
    let otherPhotoUrl: String?
    let isVideo: Bool
    let onEnd: () -> Void
    @StateObject private var callService = CallService.shared
    @State private var showConfigError = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.bgDark, Color.bgDark.opacity(0.95), Color(red: 20/255, green: 15/255, blue: 12/255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if isVideo && callService.isVideoEnabled {
                AgoraVideoView()
                    .ignoresSafeArea()
            } else {
                // Voice call or video paused – show profile
                VStack(spacing: 28) {
                    if isVideo {
                        Image(systemName: "video.slash")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.textMuted.opacity(0.8))
                        Text("Video paused")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textOnDark)
                    } else {
                        // Profile photo with glass ring
                        ZStack {
                            if let urlStr = otherPhotoUrl, !urlStr.isEmpty, let url = URL(string: urlStr) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let img) = phase {
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        profilePlaceholder
                                    }
                                }
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                                .overlay {
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.brand.opacity(0.6), Color.brand.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 3
                                        )
                                }
                                .shadow(color: Color.brand.opacity(0.3), radius: 20, x: 0, y: 8)
                            } else {
                                profilePlaceholder
                            }
                        }
                        
                        VStack(spacing: 8) {
                            Text(otherName)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.textOnDark)
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(callService.connectionState == .connected ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)
                                Text(callService.connectionState == .connected ? "Connected" : "Connecting...")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textMuted)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Glass control bar
            VStack {
                Spacer()
                HStack(spacing: 40) {
                    Button {
                        callService.toggleMute()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: callService.isMuted ? "mic.slash.fill" : "mic.fill")
                                .font(.system(size: 24))
                            Text(callService.isMuted ? "Unmute" : "Mute")
                                .font(.caption2)
                        }
                        .foregroundStyle(callService.isMuted ? Color.red : .white)
                        .frame(width: 64, height: 56)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    
                    if isVideo {
                        Button {
                            callService.toggleVideo()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: callService.isVideoEnabled ? "video.fill" : "video.slash.fill")
                                    .font(.system(size: 24))
                                Text(callService.isVideoEnabled ? "Video off" : "Video on")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 56)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            callService.switchCamera()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.rotate.fill")
                                    .font(.system(size: 24))
                                Text("Flip")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 56)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button {
                        callService.leaveChannel()
                        onEnd()
                    } label: {
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Color.red.gradient, in: Circle())
                            .shadow(color: Color.red.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(.ultraThinMaterial.opacity(0.9), in: RoundedRectangle(cornerRadius: 28))
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
        }
        .alert("Call setup", isPresented: $showConfigError) {
            Button("OK", role: .cancel) { onEnd() }
        } message: {
            Text(CallError.missingAppId.localizedDescription)
        }
    }
    
    private var profilePlaceholder: some View {
        Circle()
            .fill(Color.bgCard)
            .frame(width: 140, height: 140)
            .overlay {
                Image(systemName: "person.wave.2.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.brand.opacity(0.6))
            }
            .overlay {
                Circle()
                    .stroke(Color.brand.opacity(0.3), lineWidth: 2)
            }
    }
}

/// UIKit wrapper for Agora video views (local + remote).
struct AgoraVideoView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .black
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let engine = CallService.shared.engine else { return }
        uiView.subviews.forEach { $0.removeFromSuperview() }
        
        // Remote video (full screen)
        if let remoteUid = CallService.shared.remoteUserId {
            let remoteView = UIView()
            remoteView.frame = uiView.bounds
            remoteView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            uiView.addSubview(remoteView)
            let remoteCanvas = AgoraRtcVideoCanvas()
            remoteCanvas.uid = remoteUid
            remoteCanvas.renderMode = .hidden
            remoteCanvas.view = remoteView
            engine.setupRemoteVideo(remoteCanvas)
        }
        
        // Local video (picture-in-picture)
        let localView = UIView(frame: CGRect(x: uiView.bounds.width - 120, y: 60, width: 90, height: 120))
        localView.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        uiView.addSubview(localView)
        let localCanvas = AgoraRtcVideoCanvas()
        localCanvas.uid = 0
        localCanvas.renderMode = .hidden
        localCanvas.view = localView
        engine.setupLocalVideo(localCanvas)
    }
}
