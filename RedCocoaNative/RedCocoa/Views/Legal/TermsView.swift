import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textOnDark)
                Text("Last updated: January 2025")
                    .font(.subheadline)
                    .foregroundStyle(Color.textMuted)
                
                Text("By using Red Cocoa, you agree to use the service responsibly. You must be 18 or older. We reserve the right to suspend accounts that violate our community guidelines. We are not responsible for content shared between users.")
                    .font(.body)
                    .foregroundStyle(Color.textOnDark)
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgDark)
        .smoothAppear()
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}
