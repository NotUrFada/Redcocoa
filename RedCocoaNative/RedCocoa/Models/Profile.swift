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
}
