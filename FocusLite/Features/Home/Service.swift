/// Filtered web services opened from the home screen. YouTube comes later (roadmap V2).
enum Service: String, CaseIterable, Identifiable {
    case instagram

    var id: Self { self }

    var title: String {
        switch self {
        case .instagram: "Instagram"
        }
    }

    var detail: String {
        switch self {
        case .instagram: "Messages, profils, posts et stories, sans Reels ni Explorer."
        }
    }

    var systemImage: String {
        switch self {
        case .instagram: "camera"
        }
    }
}
