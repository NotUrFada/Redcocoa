import SwiftUI

struct ChatsListView: View {
    var selectedTab: Int
    var refreshTrigger: UUID = UUID()
    @EnvironmentObject var auth: AuthManager
    @State private var chats: [ChatPreview] = []
    @State private var loading = true
    @State private var selectedChatId: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView()
                        .tint(Color.textOnDark)
                } else if chats.isEmpty {
                    VStack(spacing: 24) {
                        Spacer()
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.textMuted.opacity(0.8))
                        Text("No messages yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textOnDark)
                        Text("When you match with someone, your conversations will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(Color.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(chats) { chat in
                        Button {
                            selectedChatId = chat.id
                        } label: {
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: chat.image ?? "")) { phase in
                                    if case .success(let img) = phase {
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Circle().fill(Color.gray.opacity(0.2))
                                            .overlay { Image(systemName: "person.circle").font(.title2).foregroundStyle(Color.textMuted) }
                                    }
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(chat.name).font(.headline).foregroundStyle(Color.textOnDark)
                                    Text(chat.lastMessage).font(.subheadline).foregroundStyle(Color.textMuted)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.bgCard)
                        .listRowSeparatorTint(Color.textMuted.opacity(0.3))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.bgDark)
            .navigationTitle("Chats")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(item: $selectedChatId) { id in
                ChatView(otherId: id)
            }
            .task(id: refreshTrigger) { await load() }
            .task(id: selectedTab) { if selectedTab == 2 { await load() } }
            .onChange(of: selectedChatId) { _, new in if new == nil { Task { await load() } } }
            .onAppear { if selectedTab == 2 { Task { await load() } } }
            .refreshable { await load() }
        }
    }
    
    private func load() async {
        do {
            chats = try await APIService.getChats(userId: auth.user?.id ?? "")
        } catch {
            chats = []
        }
        loading = false
    }
}
