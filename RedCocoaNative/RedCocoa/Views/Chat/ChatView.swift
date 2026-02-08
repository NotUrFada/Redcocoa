import SwiftUI

struct ChatView: View {
    let otherId: String
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var otherProfile: Profile?
    @State private var messages: [ChatMessage] = []
    @State private var matchId: String?
    @State private var inputText = ""
    @State private var loading = true
    @State private var icebreakerDismissed = false
    @State private var showIcebreakerCards = false
    @State private var sendError: String?
    @State private var refreshTimer: Timer?
    @State private var otherIsTyping = false
    @State private var typingDebounceTask: Task<Void, Never>?
    @State private var showVoiceRecorder = false
    @State private var callError: String?
    @State private var showInCallView = false
    @State private var activeCallIsVideo = false
    @State private var incomingCall: CallInvite?
    
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.textOnDark)
                }
                NavigationLink(destination: ProfileView(profileId: otherId)) {
                    if let p = otherProfile {
                        AsyncImage(url: URL(string: p.primaryPhoto ?? "")) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Circle().fill(Color.gray.opacity(0.2))
                            }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.name).font(.headline).foregroundStyle(Color.textOnDark)
                            if otherIsTyping {
                                Text("typing...")
                                    .font(.caption)
                                    .foregroundStyle(Color.brand)
                            }
                        }
                    } else {
                        Circle().fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Text("Loading...").font(.headline).foregroundStyle(Color.textMuted)
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                
                if otherProfile != nil {
                    Button {
                        startInAppCall(isVideo: false)
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.title3)
                            .foregroundStyle(Color.brand)
                    }
                    .buttonStyle(.plain)
                    Button {
                        startInAppCall(isVideo: true)
                    } label: {
                        Image(systemName: "video.fill")
                            .font(.title3)
                            .foregroundStyle(Color.brand)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color.bgDark)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if messages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 48))
                                    .foregroundStyle(Color.textMuted)
                                Text("No messages yet")
                                    .font(.headline)
                                    .foregroundStyle(Color.textOnDark)
                                Text("Say hi to start the conversation!")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            
                            if icebreakerSuggestion != nil {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Icebreaker idea")
                                        .font(.caption)
                                        .foregroundStyle(Color.textMuted)
                                    Text(icebreakerSuggestion!)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.textOnDark)
                                    HStack(spacing: 12) {
                                        Button("Use this") {
                                            send(text: icebreakerSuggestion!)
                                            icebreakerDismissed = true
                                        }
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color.brand)
                                        Button("Dismiss") {
                                            icebreakerDismissed = true
                                        }
                                        .font(.subheadline)
                                        .foregroundStyle(Color.textMuted)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.bgCard)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        
                        ForEach(messages) { m in
                            messageRow(m)
                        }
                    }
                    .padding()
                }
                .background(Color.bgDark)
            }
            
            if showIcebreakerCards {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ProfileOptions.icebreakerCards) { card in
                            Button {
                                let text = "\(card.emoji ?? "") \(card.label)"
                                send(text: text)
                                showIcebreakerCards = false
                            } label: {
                                HStack(spacing: 6) {
                                    if let emoji = card.emoji {
                                        Text(emoji)
                                            .font(.title2)
                                    }
                                    Text(card.label)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.textOnDark)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.bgCard)
                                .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color.bgDark)
                .overlay(alignment: .topTrailing) {
                    Button {
                        showIcebreakerCards = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.textMuted)
                    }
                    .padding(8)
                }
            }
            
            if showVoiceRecorder {
                VoiceRecorderView(
                    onRecorded: { audioData in
                        showVoiceRecorder = false
                        sendVoiceMessage(audioData: audioData)
                    },
                    onCancel: { showVoiceRecorder = false }
                )
                .padding()
                .background(Color.bgDark)
            } else {
                HStack(spacing: 12) {
                    Button {
                        showIcebreakerCards.toggle()
                    } label: {
                        Image(systemName: "square.grid.2x2")
                            .font(.title3)
                            .foregroundStyle(Color.brand)
                    }
                    Button {
                        showVoiceRecorder = true
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.title3)
                            .foregroundStyle(Color.brand)
                    }
                    TextField("Message", text: $inputText)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.bgCard)
                        .cornerRadius(24)
                        .foregroundStyle(Color.textOnDark)
                        .onChange(of: inputText) { _, _ in userDidType() }
                        .onSubmit { send() }
                    Button { send() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.brand)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
                .background(Color.bgDark)
            }
        }
        .background(Color.bgDark)
        .navigationBarHidden(true)
        .opacity(showContent ? 1 : 0)
        .task { await load() }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { showContent = true }
            startRefreshTimer()
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
            if let mid = matchId, let uid = auth.user?.id {
                Task { try? await APIService.clearTyping(matchId: mid, userId: uid) }
            }
        }
        .alert("Failed to send", isPresented: Binding(get: { sendError != nil }, set: { if !$0 { sendError = nil } })) {
            Button("OK", role: .cancel) { sendError = nil }
        } message: {
            if let err = sendError { Text(err) }
        }
        .alert("Can't call", isPresented: Binding(get: { callError != nil }, set: { if !$0 { callError = nil } })) {
            Button("OK", role: .cancel) { callError = nil }
        } message: {
            if let err = callError { Text(err) }
        }
        .fullScreenCover(isPresented: $showInCallView) {
            InCallView(otherName: otherProfile?.name ?? "Match", otherPhotoUrl: otherProfile?.primaryPhoto, isVideo: activeCallIsVideo) {
                showInCallView = false
            }
        }
        .overlay {
            if let invite = incomingCall {
                incomingCallOverlay(invite: invite)
            }
        }
    }
    
    private func startInAppCall(isVideo: Bool) {
        guard CallService.shared.hasValidConfig else {
            callError = CallError.missingAppId.localizedDescription
            return
        }
        guard let uid = auth.user?.id else {
            callError = "Sign in to call"
            return
        }
        activeCallIsVideo = isVideo
        Task {
            do {
                let mid = try await APIService.getOrCreateMatchId(userId: uid, otherId: otherId)
                // Agora channel names max 64 chars; matchId(36) + _ + suffix(12) = 49
                let suffix = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12))
                let channelName = "\(mid)_\(suffix)"
                _ = try await APIService.createCallInvite(matchId: mid, callerId: uid, calleeId: otherId, channelName: channelName, callType: isVideo ? "video" : "voice")
                let uidInt = UInt(uid.hashValue & 0x7FFFFFFF)
                try await CallService.shared.joinChannel(channelName, uid: uidInt, isVideo: isVideo)
                showInCallView = true
            } catch {
                callError = error.localizedDescription
            }
        }
    }
    
    @ViewBuilder
    private func incomingCallOverlay(invite: CallInvite) -> some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("\(otherProfile?.name ?? "Match") is calling")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(invite.callType == "video" ? "Video call" : "Voice call")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                HStack(spacing: 48) {
                    Button {
                        Task { await declineCall(invite) }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "phone.down.fill")
                                .font(.system(size: 28))
                            Text("Decline")
                                .font(.caption)
                        }
                        .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    Button {
                        Task { await answerCall(invite) }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 28))
                            Text("Answer")
                                .font(.caption)
                        }
                        .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func answerCall(_ invite: CallInvite) async {
        do {
            activeCallIsVideo = invite.callType == "video"
            try await CallService.shared.joinChannel(invite.channelName, uid: UInt((auth.user?.id.hashValue ?? 0) & 0x7FFFFFFF), isVideo: activeCallIsVideo)
            try? await APIService.updateCallStatus(inviteId: invite.id, status: "active")
            incomingCall = nil
            showInCallView = true
        } catch {
            callError = error.localizedDescription
            incomingCall = nil
        }
    }
    
    private func declineCall(_ invite: CallInvite) async {
        try? await APIService.updateCallStatus(inviteId: invite.id, status: "missed")
        incomingCall = nil
    }
    
    private var icebreakerSuggestion: String? {
        guard messages.isEmpty,
              !icebreakerDismissed,
              otherProfile?.humorPreference != "not_for_me" else { return nil }
        return ProfileOptions.icebreakerSuggestions.randomElement()
    }
    
    @MainActor
    private func load() async {
        do {
            otherProfile = try await APIService.getProfileById(otherId, userId: auth.user?.id)
            let mid = try await APIService.getMatchId(userId: auth.user?.id ?? "", otherId: otherId)
            matchId = mid
            messages = try await APIService.getMessages(userId: auth.user?.id ?? "", otherId: otherId)
            if let mid = mid, let uid = auth.user?.id {
                try? await APIService.markMessagesAsRead(userId: uid, matchId: mid)
            }
        } catch {
            otherProfile = MockData.profiles.first { $0.id == otherId }
            messages = []
        }
        loading = false
    }
    
    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                await load()
                if let mid = matchId, let uid = auth.user?.id {
                    otherIsTyping = await APIService.isOtherTyping(matchId: mid, otherId: otherId)
                    if incomingCall == nil, let invite = try? await APIService.getRingingCall(matchId: mid, calleeId: uid) {
                        incomingCall = invite
                    }
                }
            }
        }
        RunLoop.main.add(t, forMode: .common)
        refreshTimer = t
    }
    
    private func userDidType() {
        typingDebounceTask?.cancel()
        guard let mid = matchId, let uid = auth.user?.id, !inputText.isEmpty else { return }
        Task {
            try? await APIService.setTyping(matchId: mid, userId: uid)
        }
        let midCopy = mid
        let uidCopy = uid
        typingDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            try? await APIService.clearTyping(matchId: midCopy, userId: uidCopy)
        }
    }
    
    @ViewBuilder
    private func messageRow(_ m: ChatMessage) -> some View {
        HStack {
            if m.sent { Spacer() }
            VStack(alignment: m.sent ? .trailing : .leading, spacing: 2) {
                if m.isVoiceMessage, let urlStr = m.voiceUrl, let url = URL(string: urlStr) {
                    VoiceMessagePlayer(url: url, isSent: m.sent)
                } else {
                    Text(m.text)
                        .padding(12)
                        .background(m.sent ? Color.brand : Color.bgCard)
                        .foregroundStyle(m.sent ? .white : Color.textOnDark)
                        .cornerRadius(16)
                }
                if m.sent {
                    readReceiptView(for: m)
                }
            }
            if !m.sent { Spacer() }
        }
    }
    
    @ViewBuilder
    private func readReceiptView(for message: ChatMessage) -> some View {
        Group {
            if message.readAt != nil {
                let isLeftOnRead = isLastMessageFromMe(message) && !hasReplyAfter(message)
                Text(isLeftOnRead ? "Left on read" : "Read")
                    .font(.caption2)
                    .foregroundStyle(isLeftOnRead ? Color.textMuted : Color.brand)
            }
        }
    }
    
    private func isLastMessageFromMe(_ message: ChatMessage) -> Bool {
        messages.last?.id == message.id && message.sent
    }
    
    private func hasReplyAfter(_ message: ChatMessage) -> Bool {
        guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return false }
        return messages.suffix(from: idx + 1).contains { !$0.sent }
    }
    
    private func send(text: String? = nil) {
        let textToSend = text ?? inputText.trimmingCharacters(in: .whitespaces)
        guard !textToSend.isEmpty else { return }
        if text == nil { inputText = "" }
        let msg = ChatMessage(id: "temp-\(UUID().uuidString)", text: textToSend, time: "Now", sent: true, readAt: nil)
        let insertIndex = messages.count
        messages.append(msg)
        Task {
            do {
                try await APIService.sendMessage(userId: auth.user?.id ?? "", otherId: otherId, content: textToSend)
                NotificationCenter.default.post(name: .chatsDidUpdate, object: nil)
                await load()
            } catch {
                await MainActor.run {
                    sendError = error.localizedDescription
                    if insertIndex < messages.count { messages.remove(at: insertIndex) }
                }
            }
        }
    }
    
    private func sendVoiceMessage(audioData: Data) {
        guard let uid = auth.user?.id else {
            sendError = "Sign in to send"
            return
        }
        Task {
            do {
                let mid = try await APIService.getOrCreateMatchId(userId: uid, otherId: otherId)
                let url = try await APIService.uploadVoiceMessage(matchId: mid, userId: uid, audioData: audioData)
                let content = "voice:\(url)"
                try await APIService.sendMessage(userId: uid, otherId: otherId, content: content)
                NotificationCenter.default.post(name: .chatsDidUpdate, object: nil)
                await load()
            } catch {
                await MainActor.run {
                    sendError = error.localizedDescription
                }
            }
        }
    }
}
