import Foundation

struct Profile: Codable, Identifiable {
    let id: String
    var name: String
    var bio: String?
    var location: String?
    var birthDate: String?
    var photoUrls: [String]?
    var videoUrls: [String]?
    var age: Int?
    var ethnicity: String?
    var hairColor: String?
    var interests: [String]?
    var phone: String?
    var promptResponses: [String: String]?
    var humorPreference: String?
    var toneVibe: String?
    var badges: [String]?
    
    // Scientific matching metrics (optional; fallback to derived placeholder if nil)
    var bigFiveOpenness: Int? = nil
    var bigFiveConscientiousness: Int? = nil
    var bigFiveExtraversion: Int? = nil
    var bigFiveAgreeableness: Int? = nil
    var bigFiveNeuroticism: Int? = nil
    var attachmentStyle: String? = nil
    var valuesAlignmentPercent: Int? = nil
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case bio
        case location
        case birthDate = "birth_date"
        case photoUrls = "photo_urls"
        case videoUrls = "video_urls"
        case age
        case ethnicity
        case hairColor = "hair_color"
        case interests
        case phone
        case promptResponses = "prompt_responses"
        case humorPreference = "humor_preference"
        case toneVibe = "tone_vibe"
        case badges
        case bigFiveOpenness = "big_five_openness"
        case bigFiveConscientiousness = "big_five_conscientiousness"
        case bigFiveExtraversion = "big_five_extraversion"
        case bigFiveAgreeableness = "big_five_agreeableness"
        case bigFiveNeuroticism = "big_five_neuroticism"
        case attachmentStyle = "attachment_style"
        case valuesAlignmentPercent = "values_alignment_percent"
    }
    
    var primaryPhoto: String? {
        photoUrls?.first
    }
    
    var displayAge: Int? {
        if let age = age { return age }
        guard let birthDate = birthDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: birthDate) else { return nil }
        let components = Calendar.current.dateComponents([.year], from: date, to: Date())
        return components.year
    }
    
    /// Big Five scores 0–100; uses stored values or stable placeholder from id.
    func bigFiveScores() -> (O: Int, C: Int, E: Int, A: Int, N: Int) {
        let hash = abs(id.hashValue)
        return (
            O: bigFiveOpenness ?? (50 + (hash % 41)),
            C: bigFiveConscientiousness ?? (50 + ((hash / 41) % 41)),
            E: bigFiveExtraversion ?? (50 + ((hash / 1681) % 41)),
            A: bigFiveAgreeableness ?? (50 + ((hash / 68921) % 41)),
            N: bigFiveNeuroticism ?? (10 + ((hash / 2825761) % 40))
        )
    }
    
    /// Attachment style for display; uses stored value or placeholder.
    func displayAttachmentStyle() -> String {
        if let s = attachmentStyle, !s.isEmpty { return s }
        let styles = ["Secure", "Anxious", "Avoidant", "Anxious-Avoidant"]
        return styles[abs(id.hashValue) % styles.count]
    }
    
    /// Values alignment 0–100; uses stored value or placeholder.
    func displayValuesAlignment() -> Int {
        if let p = valuesAlignmentPercent, (0...100).contains(p) { return p }
        return 50 + (abs(id.hashValue) % 45)
    }
}
