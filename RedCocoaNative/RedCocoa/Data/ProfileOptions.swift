import Foundation

struct PromptOption: Identifiable {
    let id: String
    let text: String
}

struct SelectOption: Identifiable {
    let id: String
    let label: String
    var emoji: String?
}

enum ProfileOptions {
    static let allInterests: [String] = [
        "Coffee", "Photography", "Hiking", "Art", "Music", "Travel", "Yoga", "Reading",
        "Cooking", "Running", "Wine", "Architecture", "Design", "Jazz", "Movies",
        "Fitness", "Nature", "Food", "Dancing", "Gaming"
    ]
    
    static let ethnicityOptions: [String] = [
        "Black", "White", "Asian", "Hispanic/Latino", "Middle Eastern",
        "Mixed", "Other", "Prefer not to say"
    ]
    
    static let hairColorOptions: [String] = [
        "Black", "Brown", "Blonde", "Red/Ginger", "Gray",
        "Other", "Prefer not to say"
    ]
    
    static let humorOptions: [SelectOption] = [
        SelectOption(id: "love", label: "Love it", emoji: "😄"),
        SelectOption(id: "sometimes", label: "Sometimes", emoji: "😐"),
        SelectOption(id: "not_for_me", label: "Not for me", emoji: "🚫"),
    ]
    
    static let toneOptions: [SelectOption] = [
        SelectOption(id: "playful", label: "Playful"),
        SelectOption(id: "dry", label: "Dry"),
        SelectOption(id: "soft", label: "Soft"),
        SelectOption(id: "serious", label: "Serious"),
    ]
    
    static let gingerBadges: [SelectOption] = [
        SelectOption(id: "ginger_soul", label: "Has a Soul (Verified)", emoji: "🧠"),
        SelectOption(id: "ginger_fiery", label: "Allegedly Fiery", emoji: "🔥"),
        SelectOption(id: "ginger_witch", label: "Historically Accused Witch", emoji: "🧙"),
        SelectOption(id: "ginger_pain", label: "Feels Pain, Just Dramatic", emoji: "😌"),
        SelectOption(id: "ginger_chaos", label: "Chaos Magnet (Unconfirmed)", emoji: "✨"),
    ]
    
    static let blackBadges: [SelectOption] = [
        SelectOption(id: "black_culture", label: "Culture Rich", emoji: "✨"),
        SelectOption(id: "black_soft", label: "Soft Life Advocate", emoji: "😌"),
        SelectOption(id: "black_music", label: "Music Snob (Respectfully)", emoji: "🎶"),
        SelectOption(id: "black_ei", label: "Emotionally Intelligent", emoji: "🧠"),
        SelectOption(id: "black_preference", label: "Knows the Difference Between Preference & Fetish", emoji: "🔥"),
        SelectOption(id: "black_been", label: "Been Here Before", emoji: "👀"),
    ]
    
    static let allBadges: [SelectOption] = gingerBadges + blackBadges
    
    static let gingerPrompts: [PromptOption] = [
        PromptOption(id: "ginger_1", text: "The internet says gingers don't have souls. My evidence otherwise is ___."),
        PromptOption(id: "ginger_2", text: "A myth about redheads people still believe is ___."),
        PromptOption(id: "ginger_3", text: "Medieval Europe thought redheads were ___ (wrong answers only)."),
        PromptOption(id: "ginger_4", text: "Apparently my hair color means I'm ___."),
    ]
    
    static let blackPrompts: [PromptOption] = [
        PromptOption(id: "black_1", text: "Something people always assume about me that's wrong is ___."),
        PromptOption(id: "black_2", text: "A part of my culture I love sharing with the right person is ___."),
        PromptOption(id: "black_3", text: "The most unhinged thing someone has said to me on a date was ___."),
        PromptOption(id: "black_4", text: "A boundary I learned the hard way is ___."),
    ]
    
    static let allPrompts: [PromptOption] = gingerPrompts + blackPrompts
    
    static let icebreakerCards: [SelectOption] = [
        SelectOption(id: "soul", label: "Soul status: confirmed or pending?", emoji: "🧠"),
        SelectOption(id: "fiery", label: "Allegedly fiery—true or propaganda?", emoji: "🔥"),
        SelectOption(id: "boundary", label: "What's a boundary you wish people respected more?", emoji: "👀"),
        SelectOption(id: "intentional", label: "What does dating intentionally mean to you?", emoji: "🤝"),
    ]
    
    static let icebreakerSuggestions: [String] = [
        "Serious question: how many souls do you currently own?",
        "Which stereotype about you is the most wrong?",
        "What makes you feel most respected when dating?",
        "What's something from your culture you love sharing?",
    ]
    
    // MARK: - Scientific matching metrics
    static let bigFiveTraits: [(key: String, short: String, full: String)] = [
        ("O", "Openness", "Openness to experience"),
        ("C", "Conscientiousness", "Conscientiousness"),
        ("E", "Extraversion", "Extraversion"),
        ("A", "Agreeableness", "Agreeableness"),
        ("N", "Neuroticism", "Emotional stability")
    ]
    
    static let attachmentStyleLabels: [String: String] = [
        "Secure": "Secure",
        "Anxious": "Anxious",
        "Avoidant": "Avoidant",
        "Anxious-Avoidant": "Anxious-Avoidant"
    ]
}
