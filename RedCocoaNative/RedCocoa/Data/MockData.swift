import Foundation

enum MockData {
    static let profiles: [Profile] = [
        Profile(
            id: "julian",
            name: "Julian",
            bio: "Product Designer by day, amateur jazz pianist by night. Looking for someone to explore the city's hidden gems with.",
            location: "San Francisco, CA",
            birthDate: nil,
            photoUrls: ["https://images.unsplash.com/photo-1589156229687-496a31ad1d1f?w=600&h=800&fit=crop"],
            age: 26,
            ethnicity: "Black",
            hairColor: "Black",
            interests: ["Coffee", "Jazz", "Architecture"],
            phone: nil,
            promptResponses: ["black_1": "that I love jazz"]
        ),
        Profile(
            id: "sophia",
            name: "Sophia",
            bio: "Coffee enthusiast and weekend hiker. Love exploring new restaurants and spontaneous road trips.",
            location: "Oakland, CA",
            birthDate: nil,
            photoUrls: ["https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600&h=800&fit=crop"],
            age: 24,
            ethnicity: "White",
            hairColor: "Red/Ginger",
            interests: ["Photography", "Hiking", "Coffee"],
            phone: nil,
            promptResponses: ["ginger_1": "my jazz collection"]
        ),
        Profile(
            id: "sarah",
            name: "Sarah",
            bio: "Book lover and museum enthusiast. Looking for someone to share Sunday gallery walks with.",
            location: "Berkeley, CA",
            birthDate: nil,
            photoUrls: ["https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=600&h=800&fit=crop"],
            age: 27,
            ethnicity: nil,
            hairColor: nil,
            interests: ["Reading", "Art", "Yoga"],
            phone: nil,
            promptResponses: nil
        )
    ]
}
