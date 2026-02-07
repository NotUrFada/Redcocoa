import SwiftUI

struct ChatView: View {
    let otherId: String
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var otherProfile: Profile?
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var loading = true
    @State private var icebreakerDismissed = false
    @State private var showIcebreakerCards = false
    
    var body: some View {
        VStack(spacing: 0) {
            if let p = otherProfile {
                HStack(spacing: 12) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(Color.textOnDark)
                    }
                    AsyncImage(url: URL(string: p.primaryPhoto ?? "")) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Circle().fill(Color.gray.opacity(0.2))
                        }
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    Text(p.name).font(.headline).foregroundStyle(Color.textOnDark)
                    Spacer()
                }
                .padding()
                .background(Color.bgDark)
            }
            
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
                        
                        ForEach(Array(messages.enumerated()), id: \.offset) { _, m in
                            HStack {
                                if m.sent { Spacer() }
                                Text(m.text)
                                    .padding(12)
                                    .background(m.sent ? Color.brand : Color.bgCard)
                                    .foregroundStyle(m.sent ? .white : Color.textOnDark)
                                    .cornerRadius(16)
                                if !m.sent { Spacer() }
                            }
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
            
            HStack(spacing: 12) {
                Button {
                    showIcebreakerCards.toggle()
                } label: {
                    Image(systemName: "square.grid.2x2")
                        .font(.title3)
                        .foregroundStyle(Color.brand)
                }
                TextField("Message", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.bgCard)
                    .cornerRadius(24)
                    .foregroundStyle(Color.textOnDark)
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
        .background(Color.bgDark)
        .navigationBarHidden(true)
        .task { await load() }
    }
    
    private var icebreakerSuggestion: String? {
        guard messages.isEmpty,
              !icebreakerDismissed,
              otherProfile?.humorPreference != "not_for_me" else { return nil }
        return ProfileOptions.icebreakerSuggestions.randomElement()
    }
    
    private func load() async {
        do {
            otherProfile = try await APIService.getProfileById(otherId, userId: auth.user?.id)
            messages = try await APIService.getMessages(userId: auth.user?.id ?? "", otherId: otherId)
        } catch {
            otherProfile = MockData.profiles.first { $0.id == otherId }
            messages = []
        }
        loading = false
    }
    
    private func send(text: String? = nil) {
        let textToSend = text ?? inputText.trimmingCharacters(in: .whitespaces)
        guard !textToSend.isEmpty else { return }
        if text == nil { inputText = "" }
        let msg = ChatMessage(text: textToSend, time: "Now", sent: true)
        messages.append(msg)
        Task {
            try? await APIService.sendMessage(userId: auth.user?.id ?? "", otherId: otherId, content: textToSend)
        }
    }
}
