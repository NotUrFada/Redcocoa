import SwiftUI

struct DiscoverCardStack: View {
    let profile: Profile
    let onPass: () -> Void
    let onLike: () -> Void
    let onMessage: () -> Void
    var onTap: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Card - fills available space
            ProfileCardView(profile: profile)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture { onTap?() }
                .padding(.horizontal, 20)
            
            Spacer(minLength: 0)
            
            // Action buttons
            HStack(spacing: 24) {
                Button(action: onPass) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(width: 56, height: 56)
                        .background(Color.bgCard)
                        .clipShape(Circle())
                }
                .foregroundStyle(Color.textOnDark)
                
                Button(action: onMessage) {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left")
                        Text("Send message")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.brand)
                    .foregroundStyle(.white)
                    .cornerRadius(24)
                }
                
                Button(action: onLike) {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .frame(width: 56, height: 56)
                        .background(Color.brand)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 34)
        }
    }
}

struct ProfileCardView: View {
    let profile: Profile
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                // Full-bleed portrait
                AsyncImage(url: URL(string: profile.primaryPhoto ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.bgCard)
                            .overlay { ProgressView().tint(Color.textMuted) }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(Color.bgCard)
                            .overlay {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 64))
                                    .foregroundStyle(Color.textMuted)
                            }
                    @unknown default:
                        Rectangle()
                            .fill(Color.bgCard)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                
                // Brown gradient overlay (bottom to top)
                LinearGradient(
                    colors: [
                        Color.bgDark.opacity(0.95),
                        Color.bgDark.opacity(0.5),
                        Color.clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                
                // Content overlay at bottom
                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 120)
                    
                    // Category pill (interests or badge)
                    if let firstInterest = profile.interests?.first, !firstInterest.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text(firstInterest)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.brand.opacity(0.3))
                        .foregroundStyle(Color.textOnDark)
                        .cornerRadius(20)
                    }
                    
                    // Name & age
                    HStack(alignment: .firstTextBaseline) {
                        Text(profile.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.textOnDark)
                        if let age = profile.displayAge {
                            Text("• \(age)")
                                .font(.title2)
                                .foregroundStyle(Color.textMuted)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Location
                    if let location = profile.location {
                        Text(location)
                            .font(.subheadline)
                            .foregroundStyle(Color.textMuted)
                            .padding(.top, 2)
                    }
                    
                    // Bio
                    if let bio = profile.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundStyle(Color.textOnDark.opacity(0.95))
                            .lineLimit(3)
                            .padding(.top, 12)
                    }
                    
                    // Interacts/badges row
                    if let interests = profile.interests, interests.count > 1 {
                        Text(interests.dropFirst().joined(separator: " • "))
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                            .padding(.top, 8)
                    }
                    if let humor = profile.humorPreference,
                       let opt = ProfileOptions.humorOptions.first(where: { $0.id == humor }) {
                        Text("\(opt.emoji ?? "") \(opt.label)")
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .aspectRatio(3/4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
    }
}
