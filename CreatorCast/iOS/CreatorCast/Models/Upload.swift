import Foundation

struct Upload: Codable, Identifiable {
    let id: String
    let videoId: String
    let platformConfigs: [PlatformUploadConfig]
    let status: UploadStatus
    let progress: Double
    let startedAt: Date?
    let completedAt: Date?
    let error: String?
    let retryCount: Int
    let maxRetries: Int
    
    enum UploadStatus: String, Codable {
        case pending
        case processing
        case uploading
        case completed
        case failed
        case cancelled
        case scheduled
    }
    
    init(videoId: String, platformConfigs: [PlatformUploadConfig]) {
        self.id = UUID().uuidString
        self.videoId = videoId
        self.platformConfigs = platformConfigs
        self.status = .pending
        self.progress = 0.0
        self.startedAt = nil
        self.completedAt = nil
        self.error = nil
        self.retryCount = 0
        self.maxRetries = 3
    }
}

struct UploadResult: Codable {
    let platform: Platform
    let success: Bool
    let platformVideoId: String?
    let platformURL: String?
    let error: String?
    let uploadedAt: Date
    
    init(platform: Platform, success: Bool, platformVideoId: String? = nil, platformURL: String? = nil, error: String? = nil) {
        self.platform = platform
        self.success = success
        self.platformVideoId = platformVideoId
        self.platformURL = platformURL
        self.error = error
        self.uploadedAt = Date()
    }
}