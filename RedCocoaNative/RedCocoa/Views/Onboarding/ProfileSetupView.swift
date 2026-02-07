import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @EnvironmentObject var auth: AuthManager
    var onComplete: () -> Void
    
    @StateObject private var locationManager = LocationManager()
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var existingPhotoUrls: [String] = []
    @State private var videoItems: [PhotosPickerItem] = []
    @State private var videoDataItems: [(Data, String)] = []
    @State private var existingVideoUrls: [String] = []
    @State private var pickerResetId = UUID()
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
                        ForEach(Array(existingPhotoUrls.enumerated()), id: \.element) { index, urlString in
                            AsyncImage(url: URL(string: urlString)) { phase in
                                if case .success(let img) = phase {
                                    ZStack(alignment: .topTrailing) {
                                        img.resizable().aspectRatio(contentMode: .fill)
                                            .frame(height: 120).clipped().cornerRadius(12)
                                        Button { existingPhotoUrls.remove(at: index) } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white)
                                                .background(Circle().fill(Color.black.opacity(0.5)))
                                        }
                                        .padding(6)
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 12).fill(Color.bgCard).frame(height: 120)
                                }
                            }
                        }
                        ForEach(Array(0..<photoImages.count), id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: photoImages[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 120)
                                    .clipped()
                                    .cornerRadius(12)
                                Button { photoImages.remove(at: index) } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .padding(6)
                            }
                        }
                        ForEach(Array(existingVideoUrls.enumerated()), id: \.element) { index, urlString in
                            ZStack(alignment: .topTrailing) {
                                VideoThumbnailView(url: urlString)
                                    .frame(height: 120).clipped().cornerRadius(12)
                                Button { existingVideoUrls.remove(at: index) } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .padding(6)
                            }
                        }
                        ForEach(Array(0..<videoDataItems.count), id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 12).fill(Color.bgCard).frame(height: 120)
                                    .overlay { Image(systemName: "video.fill").font(.title).foregroundStyle(Color.textMuted) }
                                Button { videoDataItems.remove(at: index) } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .padding(6)
                            }
                        }
                        let photoCount = existingPhotoUrls.count + photoImages.count
                        let videoCount = existingVideoUrls.count + videoDataItems.count
                        let totalSlots = 9
                        if photoCount + videoCount < totalSlots {
                            PhotosPicker(
                                selection: $photoItems,
                                maxSelectionCount: totalSlots - photoCount - videoCount,
                                matching: .images
                            ) {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.textMuted, style: StrokeStyle(lineWidth: 2, dash: [6]))
                                    .frame(height: 120)
                                    .overlay {
                                        VStack(spacing: 8) {
                                            Image(systemName: "plus.circle").font(.title).foregroundStyle(Color.textMuted)
                                            Text("Add photo").font(.caption).foregroundStyle(Color.textMuted)
                                        }
                                    }
                            }
                            .id("photo-\(pickerResetId)")
                            .onChange(of: photoItems) { _, newItems in
                                Task {
                                    for item in newItems {
                                        if let data = try? await item.loadTransferable(type: Data.self),
                                           let img = UIImage(data: data) {
                                            await MainActor.run {
                                                if photoImages.count + existingPhotoUrls.count < 6 {
                                                    photoImages.append(img)
                                                }
                                            }
                                        }
                                    }
                                    await MainActor.run { photoItems = []; pickerResetId = UUID() }
                                }
                            }
                            PhotosPicker(
                                selection: $videoItems,
                                maxSelectionCount: min(3, totalSlots - photoCount - videoCount),
                                matching: .videos
                            ) {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.textMuted, style: StrokeStyle(lineWidth: 2, dash: [6]))
                                    .frame(height: 120)
                                    .overlay {
                                        VStack(spacing: 8) {
                                            Image(systemName: "plus.circle").font(.title).foregroundStyle(Color.textMuted)
                                            Text("Add video").font(.caption).foregroundStyle(Color.textMuted)
                                        }
                                    }
                            }
                            .id("video-\(pickerResetId)")
                            .onChange(of: videoItems) { _, newItems in
                                Task {
                                    for item in newItems {
                                        if let data = try? await item.loadTransferable(type: Data.self) {
                                            let ext = item.supportedContentTypes.first?.preferredFilenameExtension ?? "mp4"
                                            await MainActor.run {
                                                if videoDataItems.count + existingVideoUrls.count < 3 {
                                                    videoDataItems.append((data, ext))
                                                }
                                            }
                                        }
                                    }
                                    await MainActor.run { videoItems = []; pickerResetId = UUID() }
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
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgDark)
        .onChange(of: locationManager.cityName) { _, newCity in
            if let city = newCity, location.isEmpty {
                location = city
            }
        }
        .task {
            await loadExistingProfile()
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
            existingPhotoUrls = profile.photoUrls ?? []
            existingVideoUrls = profile.videoUrls ?? []
        }
    }
    
    private func save() async {
        guard let userId = auth.user?.id else { return }
        saving = true
        error = nil
        do {
            var photoUrls = existingPhotoUrls
            for img in photoImages {
                if let data = img.jpegData(compressionQuality: 0.8) {
                    let url = try await APIService.uploadProfilePhoto(userId: userId, imageData: data)
                    photoUrls.append(url)
                }
            }
            var videoUrls = existingVideoUrls
            for (data, ext) in videoDataItems {
                let url = try await APIService.uploadProfileVideo(userId: userId, videoData: data, fileExtension: ext)
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
            onComplete()
        } catch {
            self.error = error.localizedDescription
        }
        saving = false
    }
}
