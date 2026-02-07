import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var location: String = ""
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var existingPhotoUrls: [String] = []
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
        Form {
            Section("Name") {
                TextField("Name", text: $name)
                    .foregroundStyle(Color.textOnDark)
                    .listRowBackground(Color.bgCard)
            }
            
            Section("Photos") {
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
                            set: { promptResponses[prompt.id] = $0.isEmpty ? nil : $0 }
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
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(saving || name.isEmpty)
            }
        }
        .onAppear {
            name = auth.profile?.name ?? ""
            bio = auth.profile?.bio ?? ""
            location = auth.profile?.location ?? ""
            existingPhotoUrls = auth.profile?.photoUrls ?? []
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
            ForEach(Array(existingPhotoUrls.enumerated()), id: \.offset) { index, urlString in
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
                                existingPhotoUrls.remove(at: index)
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
            ForEach(0..<photoImages.count, id: \.self) { index in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: photoImages[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 100)
                        .clipped()
                        .cornerRadius(12)
                    Button {
                        photoImages.remove(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(6)
                }
            }
            if existingPhotoUrls.count + photoImages.count < 6 {
                PhotosPicker(
                    selection: $photoItems,
                    maxSelectionCount: 6 - existingPhotoUrls.count - photoImages.count,
                    matching: .images
                ) {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.textMuted, style: StrokeStyle(lineWidth: 2, dash: [6]))
                        .frame(height: 100)
                        .overlay {
                            Image(systemName: "plus.circle")
                                .font(.title)
                                .foregroundStyle(Color.textMuted)
                        }
                }
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
                        await MainActor.run { photoItems = [] }
                    }
                }
            }
        }
        .padding(.vertical, 8)
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
            if !photoUrls.isEmpty {
                try await APIService.setProfilePhotos(userId: userId, photoUrls: photoUrls)
            }
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
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        saving = false
    }
}
