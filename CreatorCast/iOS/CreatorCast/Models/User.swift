import Foundation
import Firebase

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String
    let profileImageURL: String?
    let connectedPlatforms: [String]
    let createdAt: Date
    let updatedAt: Date
    
    init(id: String, email: String, fullName: String, profileImageURL: String? = nil) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.profileImageURL = profileImageURL
        self.connectedPlatforms = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct SocialMediaAccount: Codable, Identifiable {
    let id: String
    let platform: Platform
    let username: String
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, platform, username, accessToken, refreshToken, expiresAt, isActive
    }
}