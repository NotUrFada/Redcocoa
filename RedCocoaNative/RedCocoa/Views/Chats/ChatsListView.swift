import SwiftUI

private enum ChatFilter: String, CaseIterable {
    case all = "All"
    case unread = "Unread"
    case matches = "Matches"
    case archive = "Archive"
}

struct ChatsListView: View {
    var selectedTab: Int
    var refreshTrigger: UUID = UUID()
    @Binding var openChatId: String?
    var onUnreadCountChanged: ((Int) -> Void)? = nil
    @EnvironmentObject var auth: AuthManager
    @State private var chats: [ChatPreview] = []
    @State private var loading = true
    @State private var selectedChatId: String?
    @State private var activeFilter: ChatFilter = .all
    @State private var searchQuery = ""
    @State private var showSearch = false
    
    private var newMatches: [ChatPreview] {
        Array(chats.prefix(5))
    }
    
    private var filteredChats: [ChatPreview] {
        var list = chats
        if activeFilter == .matches {
            list = Array(chats.prefix(5))
        } else if activeFilter == .archive {
            list = []
        }
        if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchQuery.lowercased()
            list = list.filter { $0.name.lowercased().contains(q) }
        }
        return list
    }
    
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
                    VStack(spacing: 0) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ChatFilter.allCases, id: \.self) { filter in
                                    Button {
                                        activeFilter = filter
                                    } label: {
                                        Text(filter.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(activeFilter == filter ? .white : Color.textOnDark)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(activeFilter == filter ? Color.brand : Color.textMuted.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(Color.bgDark)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                if !newMatches.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("NEW MATCHES")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.textMuted)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(newMatches) { chat in
                                                Button {
                                                    selectedChatId = chat.id
                                                } label: {
                                                    VStack(spacing: 6) {
                                                        AsyncImage(url: URL(string: chat.image ?? "")) { phase in
                                                            if case .success(let img) = phase {
                                                                img.resizable().aspectRatio(contentMode: .fill)
                                                            } else {
                                                                Circle().fill(Color.gray.opacity(0.3))
                                                                    .overlay { Image(systemName: "person.circle").font(.title2).foregroundStyle(Color.textMuted) }
                                                            }
                                                        }
                                                        .frame(width: 60, height: 60)
                                                        .clipShape(Circle())
                                                        .overlay(
                                                            Circle().stroke(Color.textMuted.opacity(0.3), lineWidth: 2)
                                                        )
                                                        Text(chat.name)
                                                            .font(.caption)
                                                            .fontWeight(.semibold)
                                                            .foregroundStyle(Color.textOnDark)
                                                            .lineLimit(1)
                                                    }
                                                    .frame(minWidth: 64)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            }
                            
                            if filteredChats.isEmpty {
                                VStack(spacing: 16) {
                                    Text("No conversations match your filter.")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.textMuted)
                                    Button("Show all") {
                                        activeFilter = .all
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.brand)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(filteredChats) { chat in
                                        Button {
                                            selectedChatId = chat.id
                                        } label: {
                                            HStack(spacing: 12) {
                                                AsyncImage(url: URL(string: chat.image ?? "")) { phase in
                                                    if case .success(let img) = phase {
                                                        img.resizable().aspectRatio(contentMode: .fill)
                                                    } else {
                                                        Rectangle().fill(Color.gray.opacity(0.2))
                                                            .overlay { Image(systemName: "person.circle").font(.title2).foregroundStyle(Color.textMuted) }
                                                    }
                                                }
                                                .frame(width: 56, height: 56)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                VStack(alignment: .leading, spacing: 4) {
                                                    HStack {
                                                        Text(chat.name)
                                                            .font(.headline)
                                                            .fontWeight(chat.unreadCount > 0 ? .bold : .semibold)
                                                            .foregroundStyle(Color.textOnDark)
                                                        Spacer()
                                                        if chat.unreadCount > 0 {
                                                            Text("\(chat.unreadCount)")
                                                                .font(.caption2)
                                                                .fontWeight(.bold)
                                                                .foregroundStyle(.white)
                                                                .padding(.horizontal, 6)
                                                                .padding(.vertical, 2)
                                                                .background(Color.brand)
                                                                .clipShape(Capsule())
                                                        }
                                                        Text(chat.dateStr.isEmpty ? chat.time : chat.dateStr)
                                                            .font(.caption)
                                                            .foregroundStyle(Color.textMuted)
                                                    }
                                                    Text(chat.lastMessage)
                                                        .font(.subheadline)
                                                        .foregroundStyle(chat.unreadCount > 0 ? Color.textOnDark : Color.textMuted)
                                                        .lineLimit(1)
                                                }
                                            }
                                            .padding(.vertical, 16)
                                            .padding(.horizontal, 16)
                                        }
                                        .buttonStyle(.plain)
                                        Divider()
                                            .background(Color.textMuted.opacity(0.1))
                                            .padding(.leading, 84)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .refreshable { await load() }
                    }
                }
            }
            .background(Color.bgDark)
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSearch.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.textOnDark)
                    }
                }
            }
            .overlay(alignment: .top) {
                if showSearch {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.textMuted)
                        TextField("Search conversations...", text: $searchQuery)
                            .foregroundStyle(Color.textOnDark)
                    }
                    .padding(12)
                    .background(Color.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationDestination(item: $selectedChatId) { id in
                ChatView(otherId: id)
            }
            .task(id: refreshTrigger) { await load() }
            .task(id: selectedTab) { if selectedTab == 2 { await load() } }
            .onChange(of: selectedChatId) { _, new in if new == nil { Task { await load() } } }
            .onChange(of: openChatId) { _, new in
                if let id = new {
                    selectedChatId = id
                    openChatId = nil
                }
            }
            .onAppear {
                if selectedTab == 2 { Task { await load() } }
                if let id = openChatId {
                    selectedChatId = id
                    openChatId = nil
                }
            }
            .task(id: openChatId) {
                guard let id = openChatId else { return }
                await MainActor.run {
                    selectedChatId = id
                    openChatId = nil
                }
            }
        }
    }
    
    private func load() async {
        do {
            chats = try await APIService.getChats(userId: auth.user?.id ?? "")
            let total = chats.reduce(0) { $0 + $1.unreadCount }
            await MainActor.run {
                onUnreadCountChanged?(total)
            }
        } catch {
            chats = []
            await MainActor.run {
                onUnreadCountChanged?(0)
            }
        }
        loading = false
    }
}
