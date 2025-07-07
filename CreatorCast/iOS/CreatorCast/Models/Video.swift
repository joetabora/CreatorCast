import Foundation
import AVFoundation

struct Video: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let localURL: URL
    let thumbnailURL: URL?
    let duration: TimeInterval
    let aspectRatio: AspectRatio
    let fileSize: Int64
    let createdAt: Date
    let editedAt: Date?
    let uploadStatus: UploadStatus
    
    enum AspectRatio: String, Codable, CaseIterable {
        case vertical = "9:16"    // Stories/Reels
        case square = "1:1"       // Instagram posts
        case horizontal = "16:9"   // YouTube
        
        var cgSize: CGSize {
            switch self {
            case .vertical:
                return CGSize(width: 9, height: 16)
            case .square:
                return CGSize(width: 1, height: 1)
            case .horizontal:
                return CGSize(width: 16, height: 9)
            }
        }
    }
    
    enum UploadStatus: String, Codable {
        case draft
        case processing
        case ready
        case uploading
        case uploaded
        case failed
    }
}

struct VideoEditSettings: Codable {
    var trimStart: TimeInterval = 0
    var trimEnd: TimeInterval = 0
    var cropRect: CGRect = .zero
    var filters: [VideoFilter] = []
    var overlays: [VideoOverlay] = []
    var audioTrack: AudioTrack?
    var captions: [Caption] = []
}

struct VideoFilter: Codable, Identifiable {
    let id: String
    let name: String
    let intensity: Float
    let parameters: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case id, name, intensity
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(intensity, forKey: .intensity)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        intensity = try container.decode(Float.self, forKey: .intensity)
        parameters = [:]
    }
}

struct VideoOverlay: Codable, Identifiable {
    let id: String
    let type: OverlayType
    let position: CGPoint
    let size: CGSize
    let startTime: TimeInterval
    let endTime: TimeInterval
    
    enum OverlayType: String, Codable {
        case text
        case logo
        case sticker
    }
}

struct AudioTrack: Codable, Identifiable {
    let id: String
    let name: String
    let url: URL
    let startTime: TimeInterval
    let volume: Float
}

struct Caption: Codable, Identifiable {
    let id: String
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let position: CGPoint
    let style: CaptionStyle
}

struct CaptionStyle: Codable {
    let fontName: String
    let fontSize: CGFloat
    let fontColor: String
    let backgroundColor: String
    let borderColor: String
    let borderWidth: CGFloat
}