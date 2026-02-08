import Foundation
import AgoraRtcKit

/// Manages Agora RTC for in-app voice and video calls.
/// Add AGORA_APP_ID to Info.plist. Get a temporary token from https://agora-token-generator-demo.vercel.app/ for testing.
final class CallService: NSObject, ObservableObject {
    static let shared = CallService()
    
    @Published var isInCall = false
    @Published var isMuted = false
    @Published var isVideoEnabled = true
    @Published var remoteUserId: UInt?
    @Published var connectionState: AgoraConnectionState = .disconnected
    
    private(set) var engine: AgoraRtcEngineKit?
    private var currentChannel: String?
    private var localUid: UInt = 0
    
    private override init() {
        super.init()
    }
    
    var appId: String? {
        Bundle.main.object(forInfoDictionaryKey: "AGORA_APP_ID") as? String
    }
    
    var hasValidConfig: Bool {
        guard let id = appId, !id.isEmpty else { return false }
        return true
    }
    
    func setupEngine() throws -> AgoraRtcEngineKit {
        guard let appId = appId, !appId.isEmpty else {
            throw CallError.missingAppId
        }
        if let existing = engine {
            return existing
        }
        let config = AgoraRtcEngineConfig()
        config.appId = appId
        let eng = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        eng.setChannelProfile(.communication)
        eng.setClientRole(.broadcaster)
        eng.setAudioProfile(.speechStandard)
        engine = eng
        return eng
    }
    
    func joinChannel(_ channelName: String, token: String? = nil, uid: UInt = 0, isVideo: Bool) async throws {
        let eng = try setupEngine()
        currentChannel = channelName
        localUid = uid
        
        if isVideo {
            eng.enableVideo()
            eng.enableLocalVideo(true)
            let config = AgoraVideoEncoderConfiguration(
                size: AgoraVideoDimension640x360,
                frameRate: 15,
                bitrate: 0,
                orientationMode: .adaptative,
                mirrorMode: .disabled
            )
            eng.setVideoEncoderConfiguration(config)
        } else {
            eng.disableVideo()
        }
        
        let options = AgoraRtcChannelMediaOptions()
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = isVideo
        
        let code = eng.joinChannel(byToken: token, channelId: channelName, uid: uid, mediaOptions: options)
        guard code == 0 else {
            throw CallError.agoraError(code: Int(code))
        }
        
        await MainActor.run {
            isInCall = true
            isVideoEnabled = isVideo
        }
    }
    
    func leaveChannel() {
        engine?.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
        engine = nil
        currentChannel = nil
        remoteUserId = nil
        isInCall = false
        connectionState = .disconnected
    }
    
    func toggleMute() {
        guard let eng = engine else { return }
        isMuted.toggle()
        eng.muteLocalAudioStream(isMuted)
    }
    
    func toggleVideo() {
        guard let eng = engine else { return }
        isVideoEnabled.toggle()
        eng.muteLocalVideoStream(!isVideoEnabled)
    }
    
    func switchCamera() {
        engine?.switchCamera()
    }
}

extension CallService: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        Task { @MainActor in
            connectionState = .connected
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        Task { @MainActor in
            connectionState = .disconnected
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        Task { @MainActor in
            remoteUserId = uid
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        Task { @MainActor in
            if remoteUserId == uid {
                remoteUserId = nil
            }
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionState, reason: AgoraConnectionChangedReason) {
        Task { @MainActor in
            connectionState = state
        }
    }
}

enum CallError: LocalizedError {
    case missingAppId
    case agoraError(code: Int)
    
    var errorDescription: String? {
        switch self {
        case .missingAppId: return "Add AGORA_APP_ID to Info.plist. Get an App ID from console.agora.io"
        case .agoraError(let code): return "Call failed (code: \(code))"
        }
    }
}
