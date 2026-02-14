import SwiftUI
import UIKit

/// Discover card that shows scientific matching metrics (no swipe).
struct DiscoverCardStack: View {
    let profile: Profile
    var preloadedImage: UIImage? = nil
    let onPass: () -> Void
    let onLike: () -> Void
    let onMessage: () -> Void
    var onTap: (() -> Void)?
    
    var body: some View {
        MatchingMetricsCardView(
            profile: profile,
            preloadedImage: preloadedImage,
            onPass: onPass,
            onLike: onLike,
            onMessage: onMessage,
            onTap: onTap
        )
    }
}

/// Displays Big Five, attachment style, values alignment and action buttons.
struct MatchingMetricsCardView: View {
    let profile: Profile
    var preloadedImage: UIImage? = nil
    let onPass: () -> Void
    let onLike: () -> Void
    let onMessage: () -> Void
    var onTap: (() -> Void)?
    
    private let barHeight: CGFloat = 8
    private let barCorner: CGFloat = 4
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile header (photo + name, age)
                profileHeader
                    .onTapGesture { onTap?() }
                
                // Matching metrics sections
                VStack(alignment: .leading, spacing: 24) {
                    bigFiveSection
                    attachmentSection
                    valuesSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(Color.bgDark)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionButtons
        }
    }
    
    private var profileHeader: some View {
        ZStack(alignment: .bottomLeading) {
            if let img = preloadedImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else if let urlString = profile.primaryPhoto, !urlString.isEmpty, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image): image.resizable().aspectRatio(contentMode: .fill)
                    default: Color.bgCard
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            } else {
                Color.bgCard.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            LinearGradient(
                colors: [Color.bgDark.opacity(0.9), Color.clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 120)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(profile.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textOnDark)
                    if let age = profile.displayAge {
                        Text("• \(age)")
                            .font(.body)
                            .foregroundStyle(Color.textMuted)
                    }
                }
                if let loc = profile.location {
                    Text(loc)
                        .font(.subheadline)
                        .foregroundStyle(Color.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var bigFiveSection: some View {
        let s = profile.bigFiveScores()
        let traits = ProfileOptions.bigFiveTraits
        let values = [s.O, s.C, s.E, s.A, s.N]
        return VStack(alignment: .leading, spacing: 12) {
            Text("Big Five personality")
                .font(.headline)
                .foregroundStyle(Color.textOnDark)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(traits.enumerated()), id: \.offset) { i, t in
                    HStack(spacing: 10) {
                        Text(t.short)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textOnDark)
                            .lineLimit(1)
                            .frame(minWidth: 0, maxWidth: 100, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: barCorner)
                                    .fill(Color.bgCard)
                                    .frame(height: barHeight)
                                RoundedRectangle(cornerRadius: barCorner)
                                    .fill(Color.brand)
                                    .frame(width: max(0, geo.size.width * CGFloat(values[i]) / 100), height: barHeight)
                            }
                        }
                        .frame(height: barHeight)
                        Text("\(values[i])")
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Attachment style")
                .font(.headline)
                .foregroundStyle(Color.textOnDark)
            Text(profile.displayAttachmentStyle())
                .font(.subheadline)
                .foregroundStyle(Color.textMuted)
        }
    }
    
    private var valuesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Values alignment")
                .font(.headline)
                .foregroundStyle(Color.textOnDark)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(profile.displayValuesAlignment())%")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brand)
                Text("compatibility with your stated values")
                    .font(.subheadline)
                    .foregroundStyle(Color.textMuted)
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button(action: { SoundEffectService.playPass(); onPass() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(width: 56, height: 56)
                    .background(Color.bgCard)
                    .clipShape(Circle())
            }
            .foregroundStyle(Color.textOnDark)
            .buttonStyle(.plain)
            
            Button(action: onMessage) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left")
                    Text("Send message")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.brand)
                .foregroundStyle(.white)
                .cornerRadius(24)
            }
            .buttonStyle(.plain)
            
            Button(action: { SoundEffectService.playLike(); onLike() }) {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .frame(width: 56, height: 56)
                    .background(Color.brand)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .padding(.bottom, 34)
        .background(Color.bgDark)
    }
}

struct ProfileCardView: View {
    let profile: Profile
    var preloadedImage: UIImage? = nil
    
    var body: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let h = max(geo.size.height, 1)
            ZStack(alignment: .bottomLeading) {
                Color.bgDark.frame(width: w, height: h)
                // Preloaded image shows instantly; fallback to AsyncImage only if no preload
                if let img = preloadedImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: w, height: h)
                        .clipped()
                } else if let urlString = profile.primaryPhoto, !urlString.isEmpty, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color.clear
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Color.clear
                        @unknown default:
                            Color.clear
                        }
                    }
                    .frame(width: w, height: h)
                    .clipped()
                } else {
                    Color.clear
                }
                
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

private struct SwipeOverlay: View {
    let label: String
    let color: Color
    let rotation: Double
    
    var body: some View {
        Text(label)
            .font(.system(size: 42, weight: .black))
            .foregroundStyle(color)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 5)
            )
            .padding(24)
            .rotationEffect(.degrees(rotation))
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
    }
}
