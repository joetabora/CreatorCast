import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "https://api.creatorcast.com" // Replace with your backend URL
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Generic API Request
    
    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String] = [:],
        responseType: T.Type
    ) -> AnyPublisher<T, Error> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Add default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add authentication if available
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: responseType, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) -> AnyPublisher<AuthResponse, Error> {
        let body = SignInRequest(email: email, password: password)
        let bodyData = try? JSONEncoder().encode(body)
        
        return request(
            endpoint: "/auth/signin",
            method: .POST,
            body: bodyData,
            responseType: AuthResponse.self
        )
    }
    
    func signUp(email: String, password: String, fullName: String) -> AnyPublisher<AuthResponse, Error> {
        let body = SignUpRequest(email: email, password: password, fullName: fullName)
        let bodyData = try? JSONEncoder().encode(body)
        
        return request(
            endpoint: "/auth/signup",
            method: .POST,
            body: bodyData,
            responseType: AuthResponse.self
        )
    }
    
    func refreshToken() -> AnyPublisher<AuthResponse, Error> {
        return request(
            endpoint: "/auth/refresh",
            method: .POST,
            responseType: AuthResponse.self
        )
    }
    
    // MARK: - Video Management
    
    func uploadVideo(videoData: Data, metadata: VideoMetadata) -> AnyPublisher<VideoUploadResponse, Error> {
        // Create multipart form data
        let boundary = UUID().uuidString
        let bodyData = createMultipartBody(
            boundary: boundary,
            videoData: videoData,
            metadata: metadata
        )
        
        let headers = [
            "Content-Type": "multipart/form-data; boundary=\(boundary)"
        ]
        
        return request(
            endpoint: "/videos/upload",
            method: .POST,
            body: bodyData,
            headers: headers,
            responseType: VideoUploadResponse.self
        )
    }
    
    func getVideos() -> AnyPublisher<[Video], Error> {
        return request(
            endpoint: "/videos",
            method: .GET,
            responseType: [Video].self
        )
    }
    
    func deleteVideo(id: String) -> AnyPublisher<EmptyResponse, Error> {
        return request(
            endpoint: "/videos/\(id)",
            method: .DELETE,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - Platform Uploads
    
    func uploadToPlatform(
        videoId: String,
        platform: Platform,
        config: PlatformUploadConfig
    ) -> AnyPublisher<PlatformUploadResponse, Error> {
        let body = PlatformUploadRequest(
            videoId: videoId,
            platform: platform,
            config: config
        )
        let bodyData = try? JSONEncoder().encode(body)
        
        return request(
            endpoint: "/uploads/platform",
            method: .POST,
            body: bodyData,
            responseType: PlatformUploadResponse.self
        )
    }
    
    func getUploadStatus(uploadId: String) -> AnyPublisher<UploadStatusResponse, Error> {
        return request(
            endpoint: "/uploads/\(uploadId)/status",
            method: .GET,
            responseType: UploadStatusResponse.self
        )
    }
    
    // MARK: - OAuth
    
    func getOAuthURL(platform: Platform) -> AnyPublisher<OAuthURLResponse, Error> {
        return request(
            endpoint: "/oauth/\(platform.rawValue)/url",
            method: .GET,
            responseType: OAuthURLResponse.self
        )
    }
    
    func exchangeOAuthCode(platform: Platform, code: String) -> AnyPublisher<OAuthTokenResponse, Error> {
        let body = OAuthCodeRequest(code: code, platform: platform)
        let bodyData = try? JSONEncoder().encode(body)
        
        return request(
            endpoint: "/oauth/\(platform.rawValue)/exchange",
            method: .POST,
            body: bodyData,
            responseType: OAuthTokenResponse.self
        )
    }
    
    // MARK: - Utilities
    
    private func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "auth_token")
    }
    
    private func createMultipartBody(
        boundary: String,
        videoData: Data,
        metadata: VideoMetadata
    ) -> Data {
        var body = Data()
        
        // Add video file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"video\"; filename=\"video.mov\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/quicktime\r\n\r\n".data(using: .utf8)!)
        body.append(videoData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add metadata
        if let metadataData = try? JSONEncoder().encode(metadata) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"metadata\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
            body.append(metadataData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API Models

struct SignInRequest: Codable {
    let email: String
    let password: String
}

struct SignUpRequest: Codable {
    let email: String
    let password: String
    let fullName: String
}

struct AuthResponse: Codable {
    let success: Bool
    let token: String?
    let refreshToken: String?
    let user: User?
    let error: String?
}

struct VideoMetadata: Codable {
    let title: String
    let description: String
    let tags: [String]
    let duration: TimeInterval
    let aspectRatio: String
}

struct VideoUploadResponse: Codable {
    let success: Bool
    let videoId: String?
    let url: String?
    let error: String?
}

struct PlatformUploadRequest: Codable {
    let videoId: String
    let platform: Platform
    let config: PlatformUploadConfig
}

struct PlatformUploadResponse: Codable {
    let success: Bool
    let platformVideoId: String?
    let platformURL: String?
    let error: String?
}

struct UploadStatusResponse: Codable {
    let uploadId: String
    let status: String
    let progress: Double
    let error: String?
}

struct OAuthURLResponse: Codable {
    let success: Bool
    let url: String?
    let error: String?
}

struct OAuthCodeRequest: Codable {
    let code: String
    let platform: Platform
}

struct OAuthTokenResponse: Codable {
    let success: Bool
    let accessToken: String?
    let refreshToken: String?
    let expiresAt: Date?
    let error: String?
}

struct EmptyResponse: Codable {
    let success: Bool
    let error: String?
}

// MARK: - API Errors

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}