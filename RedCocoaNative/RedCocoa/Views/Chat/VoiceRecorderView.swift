import SwiftUI
import AVFoundation

struct VoiceRecorderView: View {
    let onRecorded: (Data) -> Void
    let onCancel: () -> Void
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var recorder: AVAudioRecorder?
    @State private var recordURL: URL?
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                cancelRecording()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(Color.textMuted)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            
            if isRecording {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.title2)
                        .foregroundStyle(Color.brand)
                    Text(formatTime(recordingTime))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(Color.textOnDark)
                }
                .frame(maxWidth: .infinity)
                
                Button {
                    stopRecording()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.brand)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    startRecording()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                        Text("Hold to record")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.brand)
                    .cornerRadius(24)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
    
    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try? session.setActive(true)
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice_\(UUID().uuidString).m4a")
        recordURL = url
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.record()
            isRecording = true
            recordingTime = 0
            let t = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                recordingTime = recorder?.currentTime ?? 0
            }
            RunLoop.main.add(t, forMode: .common)
            timer = t
        } catch {
            isRecording = false
        }
    }
    
    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil
        isRecording = false
        
        if let url = recordURL, let data = try? Data(contentsOf: url) {
            try? FileManager.default.removeItem(at: url)
            onRecorded(data)
        }
        recordURL = nil
    }
    
    private func cancelRecording() {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil
        isRecording = false
        if let url = recordURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordURL = nil
        onCancel()
    }
}
