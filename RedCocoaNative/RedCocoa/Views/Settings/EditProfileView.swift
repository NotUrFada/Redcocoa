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

struct EditProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var location: String = ""
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var identifiablePhotos: [IdentifiableImage] = []
    @State private var existingPhotoUrls: [String] = []
    @State private var videoItems: [PhotosPickerItem] = []
    @State private var identifiableVideoData: [IdentifiableVideoData] = []
    @State private var existingVideoUrls: [String] = []
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
    @State private var showProfilePreview = false
    
    var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $name)
                    .foregroundStyle(Color.textOnDark)
                    .listRowBackground(Color.bgCard)
            }
            
            Section("Photos & Videos") {
                photoGrid
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            
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
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showProfilePreview = true
                } label: {
                    Image(systemName: "eye")
                    Text("Preview")
                }
                .foregroundStyle(Color.brand)
            }
            ToolbarItem(placement: .confirmationAction) {
                if saveSuccess {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Saved")
                            .foregroundStyle(.green)
                    }
                } else {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(saving || name.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showProfilePreview) {
            NavigationStack {
                ProfilePreviewView()
            }
        }
        .onAppear {
            name = auth.profile?.name ?? ""
            bio = auth.profile?.bio ?? ""
            location = auth.profile?.location ?? ""
            existingPhotoUrls = auth.profile?.photoUrls ?? []
            existingVideoUrls = auth.profile?.videoUrls ?? []
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
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(existingPhotoUrls, id: \.self) { urlString in
                AsyncImage(url: URL(string: urlString)) { phase in
                    if case .success(let img) = phase {
                        ZStack(alignment: .topTrailing) {
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 100)
                                .clipped()
                                .cornerRadius(12)
                            Button {
                                existingPhotoUrls.removeAll { $0 == urlString }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .padding(6)
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.bgCard)
                            .frame(height: 100)
                    }
                }
            }
            ForEach(existingVideoUrls, id: \.self) { urlString in
                ZStack(alignment: .topTrailing) {
                    VideoThumbnailView(url: urlString)
                        .frame(height: 100)
                        .clipped()
                        .cornerRadius(12)
                    Button {
                        existingVideoUrls.removeAll { $0 == urlString }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(6)
                }
            }
            ForEach(identifiablePhotos) { item in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: item.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 100)
                        .clipped()
                        .cornerRadius(12)
                    Button {
                        identifiablePhotos.removeAll { $0.id == item.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(6)
                }
            }
            ForEach(identifiableVideoData) { item in
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.bgCard)
                        .frame(height: 100)
                        .overlay {
                            Image(systemName: "video.fill")
                                .font(.title)
                                .foregroundStyle(Color.textMuted)
                        }
                    Button {
                        identifiableVideoData.removeAll { $0.id == item.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(6)
                }
            }
            let photoCount = existingPhotoUrls.count + identifiablePhotos.count
            let videoCount = existingVideoUrls.count + identifiableVideoData.count
            let totalSlots = 9
            if photoCount + videoCount < totalSlots {
                PhotosPicker(
                    selection: $photoItems,
                    maxSelectionCount: totalSlots - photoCount - videoCount,
                    matching: .images
                ) {
                    addSlotLabel("Add photo")
                }
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
                            let maxPhotos = 6 - existingPhotoUrls.count
                            let toAdd = loaded.prefix(max(0, maxPhotos - identifiablePhotos.count))
                            identifiablePhotos.append(contentsOf: toAdd)
                            photoItems = []
                            photoPickerResetId = UUID()
                        }
                    }
                }
                PhotosPicker(
                    selection: $videoItems,
                    maxSelectionCount: min(3, totalSlots - photoCount - videoCount),
                    matching: .videos
                ) {
                    addSlotLabel("Add video")
                }
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
                            let maxVideos = 3 - existingVideoUrls.count
                            let toAdd = loaded.prefix(max(0, maxVideos - identifiableVideoData.count))
                            identifiableVideoData.append(contentsOf: toAdd)
                            videoItems = []
                            videoPickerResetId = UUID()
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func addSlotLabel(_ text: String) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.textMuted, style: StrokeStyle(lineWidth: 2, dash: [6]))
            .frame(height: 100)
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
            var photoUrls = existingPhotoUrls
            for item in identifiablePhotos {
                if let data = item.image.jpegData(compressionQuality: 0.8) {
                    let url = try await APIService.uploadProfilePhoto(userId: userId, imageData: data)
                    photoUrls.append(url)
                }
            }
            var videoUrls = existingVideoUrls
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
