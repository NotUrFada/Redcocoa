import SwiftUI
import PhotosUI

private struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct IdentifiableVideoData: Identifiable {
    let id = UUID()
    let data: Data
    let ext: String
}

private struct IdentifiablePhotoUrl: Identifiable {
    let id = UUID()
    let url: String
}

private struct IdentifiableVideoUrl: Identifiable {
    let id = UUID()
    let url: String
}

struct EditProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var location: String = ""
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var identifiablePhotos: [IdentifiableImage] = []
    @State private var existingPhotoUrls: [IdentifiablePhotoUrl] = []
    @State private var videoItems: [PhotosPickerItem] = []
    @State private var identifiableVideoData: [IdentifiableVideoData] = []
    @State private var existingVideoUrls: [IdentifiableVideoUrl] = []
    @State private var photoPickerResetId = UUID()
    @State private var videoPickerResetId = UUID()
    @State private var saveSuccess = false
    @State private var selectedInterests: Set<String> = []
    @State private var ethnicity: String = ""
    @State private var hairColor: String = ""
    @State private var humorPreference: String = ""
    @State private var toneVibe: String = ""
    @State private var selectedBadges: Set<String> = []
    @State private var promptResponses: [String: String] = [:]
    @State private var saving = false
    @State private var error: String?
    @State private var showContent = false
    
    var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $name)
                    .foregroundStyle(Color.textOnDark)
                    .listRowBackground(Color.bgCard)
            }
            
            Section {
                photoGrid
            } header: {
                Text("Photos & Videos")
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            
            Section("Bio") {
                TextEditor(text: $bio)
                    .frame(minHeight: 100)
                    .foregroundStyle(Color.textOnDark)
                    .listRowBackground(Color.bgCard)
            }
            
            Section("Location") {
                TextField("City, State", text: $location)
                    .foregroundStyle(Color.textOnDark)
                    .listRowBackground(Color.bgCard)
                Button {
                    locationManager.requestPermission()
                    locationManager.updateLocation()
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Use current location")
                    }
                    .foregroundStyle(Color.brand)
                }
                .listRowBackground(Color.bgCard)
                if let city = locationManager.cityName {
                    Text("Detected: \(city)")
                        .font(.caption)
                        .foregroundStyle(Color.textMuted)
                        .listRowBackground(Color.bgCard)
                }
            }
            
            Section("Interests") {
                FlowLayout(spacing: 8) {
                    ForEach(ProfileOptions.allInterests, id: \.self) { interest in
                        let selected = selectedInterests.contains(interest)
                        Button {
                            if selected {
                                selectedInterests.remove(interest)
                            } else {
                                selectedInterests.insert(interest)
                            }
                        } label: {
                            Text(interest)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selected ? Color.brand : Color.bgCard)
                                .foregroundStyle(selected ? .white : Color.textOnDark)
                                .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            
            Section("Ethnicity") {
                Picker("Ethnicity", selection: $ethnicity) {
                    Text("Select").tag("")
                    ForEach(ProfileOptions.ethnicityOptions, id: \.self) { Text($0).tag($0) }
                }
                .foregroundStyle(Color.textOnDark)
                .listRowBackground(Color.bgCard)
            }
            
            Section("Hair Color") {
                Picker("Hair Color", selection: $hairColor) {
                    Text("Select").tag("")
                    ForEach(ProfileOptions.hairColorOptions, id: \.self) { Text($0).tag($0) }
                }
                .foregroundStyle(Color.textOnDark)
                .listRowBackground(Color.bgCard)
            }
            
            Section("Humor") {
                Picker("Humor preference", selection: $humorPreference) {
                    Text("Select").tag("")
                    ForEach(ProfileOptions.humorOptions) { opt in
                        Text("\(opt.emoji ?? "") \(opt.label)").tag(opt.id)
                    }
                }
                .foregroundStyle(Color.textOnDark)
                .listRowBackground(Color.bgCard)
            }
            
            Section("Tone & Vibe") {
                Picker("Tone", selection: $toneVibe) {
                    Text("Select").tag("")
                    ForEach(ProfileOptions.toneOptions) { opt in Text(opt.label).tag(opt.id) }
                }
                .foregroundStyle(Color.textOnDark)
                .listRowBackground(Color.bgCard)
            }
            
            Section("Badges (pick 1–2)") {
                FlowLayout(spacing: 8) {
                    ForEach(ProfileOptions.allBadges) { badge in
                        let selected = selectedBadges.contains(badge.id)
                        Button {
                            if selected {
                                selectedBadges.remove(badge.id)
                            } else if selectedBadges.count < 2 {
                                selectedBadges.insert(badge.id)
                            }
                        } label: {
                            Text("\(badge.emoji ?? "") \(badge.label)")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selected ? Color.brand : Color.bgCard)
                                .foregroundStyle(selected ? .white : Color.textOnDark)
                                .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                        .disabled(!selected && selectedBadges.count >= 2)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            
            Section("Prompts") {
                ForEach(ProfileOptions.allPrompts) { prompt in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prompt.text)
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                        TextField("Your answer", text: Binding(
                            get: { promptResponses[prompt.id] ?? "" },
                            set: { newValue in
                                var updated = promptResponses
                                if newValue.isEmpty {
                                    updated.removeValue(forKey: prompt.id)
                                } else {
                                    updated[prompt.id] = newValue
                                }
                                promptResponses = updated
                            }
                        ))
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color.bgCard.opacity(0.5))
                        .cornerRadius(8)
                        .foregroundStyle(Color.textOnDark)
                    }
                    .listRowBackground(Color.bgCard)
                }
            }
            
            if let error = error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .listRowBackground(Color.bgCard)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgDark)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 16)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { showContent = true }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if saveSuccess {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Saved")
                            .foregroundStyle(.green)
                    }
                } else if saving {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(Color.brand)
                        Text("Uploading...")
                            .font(.subheadline)
                            .foregroundStyle(Color.textMuted)
                    }
                } else {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            name = auth.profile?.name ?? ""
            bio = auth.profile?.bio ?? ""
            location = auth.profile?.location ?? ""
            existingPhotoUrls = (auth.profile?.photoUrls ?? []).map { IdentifiablePhotoUrl(url: $0) }
            existingVideoUrls = (auth.profile?.videoUrls ?? []).map { IdentifiableVideoUrl(url: $0) }
            selectedInterests = Set(auth.profile?.interests ?? [])
            ethnicity = auth.profile?.ethnicity ?? ""
            hairColor = auth.profile?.hairColor ?? ""
            humorPreference = auth.profile?.humorPreference ?? ""
            toneVibe = auth.profile?.toneVibe ?? ""
            selectedBadges = Set(auth.profile?.badges ?? [])
            promptResponses = auth.profile?.promptResponses ?? [:]
        }
        .onChange(of: locationManager.cityName) { _, newCity in
            if let city = newCity, location.isEmpty {
                location = city
            }
        }
    }
    
    @ViewBuilder
    private var photoGrid: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width
            let cellSize = max(90, (availableWidth - 24) / 3)
            let columns = [
                GridItem(.fixed(cellSize), spacing: 12),
                GridItem(.fixed(cellSize), spacing: 12),
                GridItem(.fixed(cellSize), spacing: 12)
            ]
            LazyVGrid(columns: columns, spacing: 12) {
            ForEach(existingPhotoUrls) { item in
                photoCell(cellSize: cellSize) {
                    AsyncImage(url: URL(string: item.url)) { phase in
                        if case .success(let img) = phase {
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.bgCard)
                        }
                    }
                } onRemove: {
                    existingPhotoUrls.removeAll { $0.id == item.id }
                }
            }
            ForEach(existingVideoUrls) { item in
                photoCell(cellSize: cellSize) {
                    VideoThumbnailView(url: item.url)
                } onRemove: {
                    existingVideoUrls.removeAll { $0.id == item.id }
                }
            }
            ForEach(identifiablePhotos) { item in
                photoCell(cellSize: cellSize) {
                    Image(uiImage: item.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } onRemove: {
                    identifiablePhotos.removeAll { $0.id == item.id }
                }
            }
            ForEach(identifiableVideoData) { item in
                photoCell(cellSize: cellSize) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.bgCard)
                        .overlay {
                            Image(systemName: "video.fill")
                                .font(.title)
                                .foregroundStyle(Color.textMuted)
                        }
                } onRemove: {
                    identifiableVideoData.removeAll { $0.id == item.id }
                }
            }
            let photoCount = existingPhotoUrls.count + identifiablePhotos.count
            let videoCount = existingVideoUrls.count + identifiableVideoData.count
            let maxPhotos = 9
            let maxVideos = 3
            if photoCount < maxPhotos {
                PhotosPicker(
                    selection: $photoItems,
                    maxSelectionCount: maxPhotos - photoCount,
                    matching: .images
                ) {
                    addSlotLabel("Add photo", cellSize: cellSize)
                }
                .buttonStyle(.plain)
                .id("photo-\(photoPickerResetId)")
                .onChange(of: photoItems) { _, newItems in
                    guard !newItems.isEmpty else { return }
                    Task {
                        var loaded: [IdentifiableImage] = []
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let img = UIImage(data: data) {
                                loaded.append(IdentifiableImage(image: img))
                            }
                        }
                        await MainActor.run {
                            let maxToAdd = maxPhotos - (existingPhotoUrls.count + identifiablePhotos.count)
                            let toAdd = loaded.prefix(max(0, maxToAdd))
                            identifiablePhotos.append(contentsOf: toAdd)
                            photoItems = []
                            photoPickerResetId = UUID()
                        }
                    }
                }
            }
            if videoCount < maxVideos {
                PhotosPicker(
                    selection: $videoItems,
                    maxSelectionCount: maxVideos - videoCount,
                    matching: .videos
                ) {
                    addSlotLabel("Add video", cellSize: cellSize)
                }
                .buttonStyle(.plain)
                .id("video-\(videoPickerResetId)")
                .onChange(of: videoItems) { _, newItems in
                    guard !newItems.isEmpty else { return }
                    Task {
                        var loaded: [IdentifiableVideoData] = []
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                let ext = item.supportedContentTypes.first?.preferredFilenameExtension ?? "mp4"
                                loaded.append(IdentifiableVideoData(data: data, ext: ext))
                            }
                        }
                        await MainActor.run {
                            let maxToAdd = maxVideos - (existingVideoUrls.count + identifiableVideoData.count)
                            let toAdd = loaded.prefix(max(0, maxToAdd))
                            identifiableVideoData.append(contentsOf: toAdd)
                            videoItems = []
                            videoPickerResetId = UUID()
                        }
                    }
                }
            }
            }
        }
        .frame(height: 400)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func photoCell<Content: View>(cellSize: CGFloat, @ViewBuilder content: () -> Content, onRemove: @escaping () -> Void) -> some View {
        ZStack(alignment: .topTrailing) {
            content()
                .frame(width: cellSize, height: cellSize)
                .clipped()
                .cornerRadius(12)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .padding(6)
            .buttonStyle(.plain)
        }
        .frame(width: cellSize, height: cellSize)
    }
    
    private func addSlotLabel(_ text: String, cellSize: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.textMuted, style: StrokeStyle(lineWidth: 2, dash: [6]))
            .frame(width: cellSize, height: cellSize)
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                        .font(.title)
                        .foregroundStyle(Color.textMuted)
                    Text(text)
                        .font(.caption2)
                        .foregroundStyle(Color.textMuted)
                }
            }
    }
    
    private func save() async {
        guard let userId = auth.user?.id else { return }
        saving = true
        error = nil
        do {
            var photoUrls = existingPhotoUrls.map { $0.url }
            for item in identifiablePhotos {
                if let data = item.image.jpegData(compressionQuality: 0.8) {
                    let url = try await APIService.uploadProfilePhoto(userId: userId, imageData: data)
                    photoUrls.append(url)
                }
            }
            var videoUrls = existingVideoUrls.map { $0.url }
            for item in identifiableVideoData {
                let url = try await APIService.uploadProfileVideo(userId: userId, videoData: item.data, fileExtension: item.ext)
                videoUrls.append(url)
            }
            try await APIService.setProfileMedia(userId: userId, photoUrls: photoUrls, videoUrls: videoUrls, name: name)
            let filtered = promptResponses.filter { !$0.value.isEmpty }
            let locToUse = location.isEmpty ? locationManager.cityName : location
            try await APIService.updateProfile(
                userId: userId,
                name: name,
                bio: bio.isEmpty ? nil : bio,
                location: locToUse,
                latitude: locationManager.location?.coordinate.latitude,
                longitude: locationManager.location?.coordinate.longitude,
                interests: selectedInterests.isEmpty ? nil : Array(selectedInterests),
                ethnicity: ethnicity.isEmpty ? nil : ethnicity,
                hairColor: hairColor.isEmpty ? nil : hairColor,
                humorPreference: humorPreference.isEmpty ? nil : humorPreference,
                toneVibe: toneVibe.isEmpty ? nil : toneVibe,
                badges: selectedBadges.isEmpty ? nil : Array(selectedBadges),
                promptResponses: filtered.isEmpty ? nil : filtered
            )
            await auth.fetchProfile(userId: userId)
            NotificationCenter.default.post(name: .profileDidUpdate, object: nil)
            saveSuccess = true
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        saving = false
    }
}
