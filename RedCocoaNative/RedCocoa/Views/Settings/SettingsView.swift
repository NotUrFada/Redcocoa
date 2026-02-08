import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject private var locationManager = LocationManager()
    @State private var showDeleteConfirm = false
    @State private var showDeleteError = false
    @State private var deleteError: String?
    @State private var deleting = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Group {
                            if let urlString = auth.profile?.primaryPhoto, let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure:
                                        Circle()
                                            .fill(Color.brand)
                                    case .empty:
                                        Circle()
                                            .fill(Color.brand)
                                            .overlay { ProgressView().tint(.white) }
                                    @unknown default:
                                        Circle()
                                            .fill(Color.brand)
                                    }
                                }
                            } else {
                                Circle()
                                    .fill(Color.brand)
                            }
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(auth.profile?.name ?? "User")
                                .font(.headline)
                                .foregroundStyle(Color.textOnDark)
                            Text(auth.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(Color.textMuted)
                        }
                    }
                    .listRowBackground(Color.bgCard)
                    .padding(.vertical, 8)
                }
                
                Section("Account") {
                    NavigationLink(destination: EditProfileView()) { Text("Edit Profile").foregroundStyle(Color.textOnDark) }
                    NavigationLink(destination: ProfilePreviewView()) { Text("Preview Profile").foregroundStyle(Color.textOnDark) }
                    NavigationLink(destination: PhoneNumberView()) { Text("Phone Number").foregroundStyle(Color.textOnDark) }
                }
                .listRowBackground(Color.bgCard)
                
                Section("Location") {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(Color.brand)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Location")
                                .foregroundStyle(Color.textOnDark)
                            Text(locationStatusText)
                                .font(.caption)
                                .foregroundStyle(Color.textMuted)
                        }
                        Spacer()
                        Button(locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways ? "Update" : "Enable") {
                            locationManager.requestPermission()
                            locationManager.updateLocation()
                        }
                        .foregroundStyle(Color.brand)
                    }
                    .listRowBackground(Color.bgCard)
                    if let city = locationManager.cityName ?? auth.profile?.location {
                        Text(city)
                            .font(.subheadline)
                            .foregroundStyle(Color.textMuted)
                            .listRowBackground(Color.bgCard)
                    }
                }
                
                Section("Notifications") {
                    Toggle(isOn: Binding(
                        get: { UserPreferencesService.notificationsNewMatches },
                        set: { UserPreferencesService.notificationsNewMatches = $0 }
                    )) {
                        Text("New Matches")
                            .foregroundStyle(Color.textOnDark)
                    }
                    .listRowBackground(Color.bgCard)
                    Toggle(isOn: Binding(
                        get: { UserPreferencesService.notificationsMessages },
                        set: { UserPreferencesService.notificationsMessages = $0 }
                    )) {
                        Text("Messages")
                            .foregroundStyle(Color.textOnDark)
                    }
                    .listRowBackground(Color.bgCard)
                    Toggle(isOn: Binding(
                        get: { UserPreferencesService.notificationsAppActivity },
                        set: { UserPreferencesService.notificationsAppActivity = $0 }
                    )) {
                        Text("App Activity")
                            .foregroundStyle(Color.textOnDark)
                    }
                    .listRowBackground(Color.bgCard)
                }
                
                Section("Legal") {
                    NavigationLink(destination: PrivacyPolicyView()) { Text("Privacy Policy").foregroundStyle(Color.textOnDark) }
                    NavigationLink(destination: TermsView()) { Text("Terms of Service").foregroundStyle(Color.textOnDark) }
                }
                .listRowBackground(Color.bgCard)
                
                Section {
                    Button("Log Out", role: .destructive) {
                        Task { await auth.signOut() }
                    }
                }
                .listRowBackground(Color.bgCard)
                
                Section {
                    Button("Delete Account", role: .destructive) {
                        showDeleteConfirm = true
                    }
                    .disabled(deleting)
                }
                .listRowBackground(Color.bgCard)
            }
            .scrollContentBackground(.hidden)
            .confirmationDialog("Delete Account", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete Account", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all your data. This action cannot be undone.")
            }
            .alert("Error", isPresented: $showDeleteError) {
                Button("OK") { showDeleteError = false }
            } message: {
                if let error = deleteError {
                    Text(error)
                }
            }
            .background(Color.bgDark)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationTitle("Profile")
        }
    }
    
    private var locationStatusText: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "Enabled for discovery"
        case .denied:
            return "Disabled"
        case .restricted:
            return "Restricted"
        default:
            return "Tap to enable"
        }
    }
    
    private func deleteAccount() async {
        deleting = true
        deleteError = nil
        showDeleteConfirm = false
        do {
            try await auth.deleteAccount()
        } catch {
            deleteError = error.localizedDescription
            showDeleteError = true
        }
        deleting = false
    }
}
