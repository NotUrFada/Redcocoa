import SwiftUI
import PhotosUI

private struct ProfileSetupIdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct ProfileSetupIdentifiableVideoData: Identifiable {
    let id = UUID()
    let data: Data
    let ext: String
}

private struct ProfileSetupIdentifiablePhotoUrl: Identifiable {
    let id = UUID()
    let url: String
}

private struct ProfileSetupIdentifiableVideoUrl: Identifiable {
    let id = UUID()
    let url: String
}

struct ProfileSetupView: View {
    @EnvironmentObject var auth: AuthManager
    var onComplete: () -> Void
    
    @StateObject private var locationManager = LocationManager()
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var identifiablePhotos: [ProfileSetupIdentifiableImage] = []
    @State private var existingPhotoUrls: [ProfileSetupIdentifiablePhotoUrl] = []
    @State private var videoItems: [PhotosPickerItem] = []
    @State private var identifiableVideoData: [ProfileSetupIdentifiableVideoData] = []
    @State private var existingVideoUrls: [ProfileSetupIdentifiableVideoUrl] = []
    @State private var photoPickerResetId = UUID()
    @State private var videoPickerResetId = UUID()
    @State private var location: String = ""
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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Set up your profile")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textOnDark)
                
                // Photos & Videos section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add your photos & videos")
                        .font(.headline)
                        .foregroundStyle(Color.textOnDark)
                    Text("Profiles with photos get more matches. Add at least 1 photo.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textMuted)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(existingPhotoUrls) { item in
                            profileSetupPhotoCell {
                                AsyncImage(url: URL(string: item.url)) { phase in
                                    if case .success(let img) = phase {
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        RoundedRectangle(cornerRadius: 12).fill(Color.bgCard)
                                    }
                                }
                            } onRemove: {
                                existingPhotoUrls.removeAll { $0.id == item.id }
                            }
                        }
                        ForEach(identifiablePhotos) { item in
                            profileSetupPhotoCell {
                                Image(uiImage: item.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } onRemove: {
                                identifiablePhotos.removeAll { $0.id == item.id }
                            }
                        }
                        ForEach(existingVideoUrls) { item in
                            profileSetupPhotoCell {
                                VideoThumbnailView(url: item.url)
                            } onRemove: {
                                existingVideoUrls.removeAll { $0.id == item.id }
                            }
                        }
                        ForEach(identifiableVideoData) { item in
                            profileSetupPhotoCell {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.bgCard)
                                    .overlay { Image(systemName: "video.fill").font(.title).foregroundStyle(Color.textMuted) }
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
                                profileSetupAddSlotLabel("Add photo")
                            }
                            .buttonStyle(.plain)
                            .id("photo-\(photoPickerResetId)")
                            .onChange(of: photoItems) { _, newItems in
                                guard !newItems.isEmpty else { return }
                                Task {
                                    var loaded: [ProfileSetupIdentifiableImage] = []
                                    for item in newItems {
                                        if let data = try? await item.loadTransferable(type: Data.self),
                                           let img = UIImage(data: data) {
                                            loaded.append(ProfileSetupIdentifiableImage(image: img))
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
                                profileSetupAddSlotLabel("Add video")
                            }
                            .buttonStyle(.plain)
                            .id("video-\(videoPickerResetId)")
                            .onChange(of: videoItems) { _, newItems in
                                guard !newItems.isEmpty else { return }
                                Task {
                                    var loaded: [ProfileSetupIdentifiableVideoData] = []
                                    for item in newItems {
                                        if let data = try? await item.loadTransferable(type: Data.self) {
                                            let ext = item.supportedContentTypes.first?.preferredFilenameExtension ?? "mp4"
                                            loaded.append(ProfileSetupIdentifiableVideoData(data: data, ext: ext))
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
                
                // Location
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location")
                        .font(.headline)
                        .foregroundStyle(Color.textOnDark)
                    TextField("City, State", text: $location)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.bgCard)
                        .cornerRadius(12)
                        .foregroundStyle(Color.textOnDark)
                    Button {
                        locationManager.requestPermission()
                        locationManager.updateLocation()
                    } label: {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Use current location")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.brand)
                    }
                }
                
                // Interests
                VStack(alignment: .leading, spacing: 12) {
                    Text("Interests")
                        .font(.headline)
                        .foregroundStyle(Color.textOnDark)
                    FlowLayout(spacing: 8) {
                        ForEach(ProfileOptions.allInterests, id: \.self) { interest in
                            let selected = selectedInterests.contains(interest)
                            Button {
                                if selected { selectedInterests.remove(interest) }
                                else { selectedInterests.insert(interest) }
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
                }
                
                // Humor & Tone
                VStack(alignment: .leading, spacing: 12) {
                    Text("Humor & Vibe")
                        .font(.headline)
                        .foregroundStyle(Color.textOnDark)
                    HStack(spacing: 8) {
                        ForEach(ProfileOptions.humorOptions) { opt in
                            let selected = humorPreference == opt.id
                            Button {
                                humorPreference = selected ? "" : opt.id
                            } label: {
                                Text("\(opt.emoji ?? "") \(opt.label)")
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
                    HStack(spacing: 8) {
                        ForEach(ProfileOptions.toneOptions) { opt in
                            let selected = toneVibe == opt.id
                            Button {
                                toneVibe = selected ? "" : opt.id
                            } label: {
                                Text(opt.label)
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
                }
                
                // Ethnicity & Hair
                VStack(alignment: .leading, spacing: 12) {
                    Text("About you")
                        .font(.headline)
                        .foregroundStyle(Color.textOnDark)
                    HStack(spacing: 12) {
                        Picker("Ethnicity", selection: $ethnicity) {
                            Text("Ethnicity").tag("")
                            ForEach(ProfileOptions.ethnicityOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .padding(8)
                        .background(Color.bgCard)
                        .cornerRadius(12)
                        .foregroundStyle(Color.textOnDark)
                        Picker("Hair", selection: $hairColor) {
                            Text("Hair").tag("")
                            ForEach(ProfileOptions.hairColorOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .padding(8)
                        .background(Color.bgCard)
                        .cornerRadius(12)
                        .foregroundStyle(Color.textOnDark)
                    }
                }
                
                // Badges (1-2)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Badges (pick 1–2)")
                        .font(.headline)
                        .foregroundStyle(Color.textOnDark)
                    FlowLayout(spacing: 8) {
                        ForEach(ProfileOptions.allBadges) { badge in
                            let selected = selectedBadges.contains(badge.id)
                            Button {
                                if selected { selectedBadges.remove(badge.id) }
                                else if selectedBadges.count < 2 { selectedBadges.insert(badge.id) }
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
                        }
                    }
                }
                
                // Prompts section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Prompts (optional)")
                        .font(.headline)
                        .foregroundStyle(Color.textOnDark)
                    Text("Answer a few prompts to show your personality.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textMuted)
                    
                    ForEach(ProfileOptions.allPrompts) { prompt in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(prompt.text.replacingOccurrences(of: "___", with: "___"))
                                .font(.subheadline)
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
                            .padding()
                            .background(Color.bgCard)
                            .cornerRadius(12)
                            .foregroundStyle(Color.textOnDark)
                        }
                    }
                }
                
                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                Button {
                    Task { await save() }
                } label: {
                    if saving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Save & continue")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.brand)
                .foregroundStyle(.white)
                .cornerRadius(24)
                .fontWeight(.semibold)
                .disabled(saving)
                
                Button("Skip for now") {
                    onComplete()
                }
                .font(.subheadline)
                .foregroundStyle(Color.textMuted)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgDark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { showContent = true }
        }
        .onChange(of: locationManager.cityName) { _, newCity in
            if let city = newCity, location.isEmpty {
                location = city
            }
        }
        .task {
            await loadExistingProfile()
        }
    }
    
    @ViewBuilder
    private func profileSetupPhotoCell<Content: View>(@ViewBuilder content: () -> Content, onRemove: @escaping () -> Void) -> some View {
        ZStack(alignment: .topTrailing) {
            content()
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
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
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func profileSetupAddSlotLabel(_ text: String) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.textMuted, style: StrokeStyle(lineWidth: 2, dash: [6]))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle").font(.title).foregroundStyle(Color.textMuted)
                    Text(text).font(.caption).foregroundStyle(Color.textMuted)
                }
            }
    }
    
    private func loadExistingProfile() async {
        guard let profile = auth.profile else { return }
        await MainActor.run {
            if let loc = profile.location { location = loc }
            if let ints = profile.interests { selectedInterests = Set(ints) }
            if let eth = profile.ethnicity { ethnicity = eth }
            if let hair = profile.hairColor { hairColor = hair }
            if let humor = profile.humorPreference { humorPreference = humor }
            if let tone = profile.toneVibe { toneVibe = tone }
            if let bgs = profile.badges { selectedBadges = Set(bgs) }
            if let pr = profile.promptResponses { promptResponses = pr }
            existingPhotoUrls = (profile.photoUrls ?? []).map { ProfileSetupIdentifiablePhotoUrl(url: $0) }
            existingVideoUrls = (profile.videoUrls ?? []).map { ProfileSetupIdentifiableVideoUrl(url: $0) }
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
            try await APIService.setProfileMedia(userId: userId, photoUrls: photoUrls, videoUrls: videoUrls, name: auth.profile?.name ?? "User")
            let filtered = promptResponses.filter { !$0.value.isEmpty }
            let locToUse = location.isEmpty ? locationManager.cityName : location
            try await APIService.upsertProfile(
                userId: userId,
                name: auth.profile?.name ?? "User",
                bio: auth.profile?.bio,
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
            onComplete()
        } catch {
            self.error = error.localizedDescription
        }
        saving = false
    }
}
