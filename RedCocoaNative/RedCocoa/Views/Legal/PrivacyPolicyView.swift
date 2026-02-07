import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        List {
            Section {
                Text("Last updated: January 2025")
                    .font(.subheadline)
                    .foregroundStyle(Color.textMuted)
                    .listRowBackground(Color.bgCard)
            } header: {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textOnDark)
            }
            
            Section("1. Information We Collect") {
                Text("We collect information you provide directly: profile details (name, photos, bio, preferences), messages, and usage data. We use device information for app functionality.")
                    .foregroundStyle(Color.textMuted)
                    .listRowBackground(Color.bgCard)
            }
            
            Section("2. How We Use Your Information") {
                Text("We use your information to provide matching, messaging, and personalized features. We may use aggregated data to improve our services.")
                    .foregroundStyle(Color.textMuted)
                    .listRowBackground(Color.bgCard)
            }
            
            Section("3. Sharing Your Information") {
                Text("Your profile is visible to other users based on your preferences. We do not sell your personal information. We may share data with service providers who assist our operations.")
                    .foregroundStyle(Color.textMuted)
                    .listRowBackground(Color.bgCard)
            }
            
            Section("4. Data Security") {
                Text("We implement industry-standard security measures to protect your data. Messages are encrypted in transit.")
                    .foregroundStyle(Color.textMuted)
                    .listRowBackground(Color.bgCard)
            }
            
            Section("5. Your Rights") {
                Text("You may access, correct, or delete your data through the app settings. You may request a copy of your data or withdraw consent at any time.")
                    .foregroundStyle(Color.textMuted)
                    .listRowBackground(Color.bgCard)
            }
            
            Section("6. Contact") {
                Text("For privacy inquiries: privacy@redcocoa.app")
                    .foregroundStyle(Color.textMuted)
                    .listRowBackground(Color.bgCard)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.bgDark)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
