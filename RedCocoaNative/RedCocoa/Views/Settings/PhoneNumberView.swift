import SwiftUI

struct PhoneNumberView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var phone: String = ""
    @State private var saving = false
    @State private var error: String?
    @State private var saved = false
    
    var body: some View {
        Form {
            Section {
                TextField("Phone number", text: $phone)
                    .keyboardType(.phonePad)
                    .foregroundStyle(Color.textOnDark)
                    .listRowBackground(Color.bgCard)
            }
            if let error = error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .listRowBackground(Color.bgCard)
                }
            }
            if saved {
                Section {
                    Text("Phone number saved.")
                        .foregroundStyle(.green)
                        .listRowBackground(Color.bgCard)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgDark)
        .smoothAppear()
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationTitle("Phone Number")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(saving)
            }
        }
        .onAppear {
            phone = auth.profile?.phone ?? ""
        }
    }
    
    private func save() async {
        guard let userId = auth.user?.id else { return }
        saving = true
        error = nil
        saved = false
        do {
            try await APIService.updateProfilePhone(userId: userId, phone: phone.trimmingCharacters(in: .whitespaces))
            await auth.fetchProfile(userId: userId)
            saved = true
        } catch {
            self.error = error.localizedDescription
        }
        saving = false
    }
}
