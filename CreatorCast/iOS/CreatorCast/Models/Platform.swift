import Foundation

enum Platform: String, Codable, CaseIterable, Identifiable {
    case youtube = "youtube"
    case tiktok = "tiktok"
    case instagram = "instagram"
    case facebook = "facebook"
    case twitter = "twitter"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .youtube:
            return "YouTube Shorts"
        case .tiktok:
            return "TikTok"
        case .instagram:
            return "Instagram Reels"
        case .facebook:
            return "Facebook Reels"
        case .twitter:
            return "X (Twitter)"
        }
    }
    
    var icon: String {
        switch self {
        case .youtube:
            return "play.rectangle.fill"
        case .tiktok:
            return "music.note"
        case .instagram:
            return "camera.fill"
        case .facebook:
            return "person.3.fill"
        case .twitter:
            return "bird.fill"
        }
    }
    
    var color: String {
        switch self {
        case .youtube:
            return "#FF0000"
        case .tiktok:
            return "#000000"
        case .instagram:
            return "#E4405F"
        case .facebook:
            return "#1877F2"
        case .twitter:
            return "#1DA1F2"
        }
    }
    
    var maxDuration: TimeInterval {
        switch self {
        case .youtube:
            return 60 // 60 seconds for Shorts
        case .tiktok:
            return 180 // 3 minutes
        case .instagram:
            return 90 // 90 seconds for Reels
        case .facebook:
            return 90 // 90 seconds for Reels
        case .twitter:
            return 140 // 2 minutes 20 seconds
        }
    }
    
    var supportedAspectRatios: [Video.AspectRatio] {
        switch self {
        case .youtube:
            return [.vertical, .square]
        case .tiktok:
            return [.vertical]
        case .instagram:
            return [.vertical, .square]
        case .facebook:
            return [.vertical, .square]
        case .twitter:
            return [.vertical, .square, .horizontal]
        }
    }
    
    var maxFileSize: Int64 {
        switch self {
        case .youtube:
            return 256 * 1024 * 1024 // 256MB
        case .tiktok:
            return 287 * 1024 * 1024 // 287MB
        case .instagram:
            return 100 * 1024 * 1024 // 100MB
        case .facebook:
            return 100 * 1024 * 1024 // 100MB
        case .twitter:
            return 512 * 1024 * 1024 // 512MB
        }
    }
}

struct PlatformUploadConfig: Codable, Identifiable {
    let id: String
    let platform: Platform
    let title: String
    let description: String
    let tags: [String]
    let thumbnailURL: URL?
    let scheduledDate: Date?
    let isPrivate: Bool
    let allowComments: Bool
    let allowDuet: Bool // TikTok specific
    let allowStitch: Bool // TikTok specific
    
    init(platform: Platform, title: String = "", description: String = "") {
        self.id = UUID().uuidString
        self.platform = platform
        self.title = title
        self.description = description
        self.tags = []
        self.thumbnailURL = nil
        self.scheduledDate = nil
        self.isPrivate = false
        self.allowComments = true
        self.allowDuet = true
        self.allowStitch = true
    }
}