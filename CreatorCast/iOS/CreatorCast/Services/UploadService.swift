import Foundation
import Combine

class UploadService: ObservableObject {
    static let shared = UploadService()
    
    @Published var uploads: [Upload] = []
    @Published var isUploading = false
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    
    init() {
        loadUploads()
    }
    
    // MARK: - Upload Management
    
    func startUpload(_ upload: Upload, completion: @escaping (Bool) -> Void) {
        var updatedUpload = upload
        updatedUpload = updateUploadStatus(upload, status: .processing, progress: 0.0)
        
        isUploading = true
        
        // Start upload process
        processUpload(updatedUpload) { [weak self] success in
            DispatchQueue.main.async {
                self?.isUploading = false
                completion(success)
            }
        }
    }
    
    func retryUpload(_ upload: Upload) {
        guard upload.retryCount < upload.maxRetries else {
            print("Max retries reached for upload: \(upload.id)")
            return
        }
        
        var updatedUpload = upload
        updatedUpload = updateUploadStatus(upload, status: .processing, progress: 0.0, retryCount: upload.retryCount + 1)
        
        processUpload(updatedUpload) { _ in }
    }
    
    func cancelUpload(_ upload: Upload) {
        let updatedUpload = updateUploadStatus(upload, status: .cancelled, progress: 0.0)
        saveUpload(updatedUpload)
    }
    
    func clearCompletedUploads() {
        uploads.removeAll { $0.status == .completed }
        saveUploads()
    }
    
    // MARK: - Upload Processing
    
    private func processUpload(_ upload: Upload, completion: @escaping (Bool) -> Void) {
        let dispatchGroup = DispatchGroup()
        var uploadResults: [UploadResult] = []
        var hasFailures = false
        
        // Upload to each platform
        for config in upload.platformConfigs {
            dispatchGroup.enter()
            
            uploadToPlatform(upload: upload, config: config) { result in
                uploadResults.append(result)
                if !result.success {
                    hasFailures = true
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            let finalStatus: Upload.UploadStatus = hasFailures ? .failed : .completed
            let finalProgress = hasFailures ? upload.progress : 1.0
            
            let updatedUpload = self?.updateUploadStatus(
                upload,
                status: finalStatus,
                progress: finalProgress,
                error: hasFailures ? "Some uploads failed" : nil
            )
            
            if let updatedUpload = updatedUpload {
                self?.saveUpload(updatedUpload)
            }
            
            completion(!hasFailures)
        }
    }
    
    private func uploadToPlatform(upload: Upload, config: PlatformUploadConfig, completion: @escaping (UploadResult) -> Void) {
        updateUploadProgress(upload, progress: 0.1)
        
        // Platform-specific upload logic
        switch config.platform {
        case .youtube:
            uploadToYouTube(upload: upload, config: config, completion: completion)
        case .tiktok:
            uploadToTikTok(upload: upload, config: config, completion: completion)
        case .instagram:
            uploadToInstagram(upload: upload, config: config, completion: completion)
        case .facebook:
            uploadToFacebook(upload: upload, config: config, completion: completion)
        case .twitter:
            uploadToTwitter(upload: upload, config: config, completion: completion)
        }
    }
    
    // MARK: - Platform-Specific Uploads
    
    private func uploadToYouTube(upload: Upload, config: PlatformUploadConfig, completion: @escaping (UploadResult) -> Void) {
        // Simulate upload process
        simulateUpload(platform: .youtube, delay: 3.0) { success in
            let result = UploadResult(
                platform: .youtube,
                success: success,
                platformVideoId: success ? "YT_\(UUID().uuidString)" : nil,
                platformURL: success ? "https://youtube.com/shorts/\(UUID().uuidString)" : nil,
                error: success ? nil : "YouTube upload failed"
            )
            completion(result)
        }
    }
    
    private func uploadToTikTok(upload: Upload, config: PlatformUploadConfig, completion: @escaping (UploadResult) -> Void) {
        simulateUpload(platform: .tiktok, delay: 2.5) { success in
            let result = UploadResult(
                platform: .tiktok,
                success: success,
                platformVideoId: success ? "TT_\(UUID().uuidString)" : nil,
                platformURL: success ? "https://tiktok.com/@user/video/\(UUID().uuidString)" : nil,
                error: success ? nil : "TikTok upload failed"
            )
            completion(result)
        }
    }
    
    private func uploadToInstagram(upload: Upload, config: PlatformUploadConfig, completion: @escaping (UploadResult) -> Void) {
        simulateUpload(platform: .instagram, delay: 4.0) { success in
            let result = UploadResult(
                platform: .instagram,
                success: success,
                platformVideoId: success ? "IG_\(UUID().uuidString)" : nil,
                platformURL: success ? "https://instagram.com/reel/\(UUID().uuidString)" : nil,
                error: success ? nil : "Instagram upload failed"
            )
            completion(result)
        }
    }
    
    private func uploadToFacebook(upload: Upload, config: PlatformUploadConfig, completion: @escaping (UploadResult) -> Void) {
        simulateUpload(platform: .facebook, delay: 3.5) { success in
            let result = UploadResult(
                platform: .facebook,
                success: success,
                platformVideoId: success ? "FB_\(UUID().uuidString)" : nil,
                platformURL: success ? "https://facebook.com/reel/\(UUID().uuidString)" : nil,
                error: success ? nil : "Facebook upload failed"
            )
            completion(result)
        }
    }
    
    private func uploadToTwitter(upload: Upload, config: PlatformUploadConfig, completion: @escaping (UploadResult) -> Void) {
        simulateUpload(platform: .twitter, delay: 2.0) { success in
            let result = UploadResult(
                platform: .twitter,
                success: success,
                platformVideoId: success ? "X_\(UUID().uuidString)" : nil,
                platformURL: success ? "https://x.com/user/status/\(UUID().uuidString)" : nil,
                error: success ? nil : "X (Twitter) upload failed"
            )
            completion(result)
        }
    }
    
    // MARK: - Upload Utilities
    
    private func simulateUpload(platform: Platform, delay: TimeInterval, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) {
            // Simulate 90% success rate
            let success = Int.random(in: 1...10) <= 9
            completion(success)
        }
    }
    
    private func updateUploadStatus(_ upload: Upload, status: Upload.UploadStatus, progress: Double, error: String? = nil, retryCount: Int? = nil) -> Upload {
        var updatedUpload = upload
        
        // Use reflection to update the upload (since Upload is a struct with let properties)
        // In a real implementation, you'd modify the Upload struct to have var properties
        // For now, we'll create a new Upload instance
        let newUpload = Upload(videoId: upload.videoId, platformConfigs: upload.platformConfigs)
        
        // Update the upload in the array
        if let index = uploads.firstIndex(where: { $0.id == upload.id }) {
            uploads[index] = newUpload
        } else {
            uploads.append(newUpload)
        }
        
        saveUploads()
        return newUpload
    }
    
    private func updateUploadProgress(_ upload: Upload, progress: Double) {
        if let index = uploads.firstIndex(where: { $0.id == upload.id }) {
            // Update progress - in a real implementation, you'd have a mutable progress property
            print("Upload \(upload.id) progress: \(Int(progress * 100))%")
        }
    }
    
    private func saveUpload(_ upload: Upload) {
        if let index = uploads.firstIndex(where: { $0.id == upload.id }) {
            uploads[index] = upload
        } else {
            uploads.append(upload)
        }
        saveUploads()
    }
    
    // MARK: - Persistence
    
    private func loadUploads() {
        guard let data = UserDefaults.standard.data(forKey: "SavedUploads"),
              let savedUploads = try? JSONDecoder().decode([Upload].self, from: data) else {
            return
        }
        uploads = savedUploads
    }
    
    private func saveUploads() {
        if let data = try? JSONEncoder().encode(uploads) {
            UserDefaults.standard.set(data, forKey: "SavedUploads")
        }
    }
    
    // MARK: - Public Interface
    
    func refreshUploads() async {
        // Refresh upload status from backend
        await MainActor.run {
            // Simulate refresh
            print("Refreshing uploads...")
        }
    }
}

extension UploadService {
    // Mock data for testing
    func addMockUploads() {
        let mockUpload1 = Upload(
            videoId: "mock_video_1",
            platformConfigs: [
                PlatformUploadConfig(platform: .youtube, title: "Test Video 1"),
                PlatformUploadConfig(platform: .tiktok, title: "Test Video 1")
            ]
        )
        
        let mockUpload2 = Upload(
            videoId: "mock_video_2",
            platformConfigs: [
                PlatformUploadConfig(platform: .instagram, title: "Test Video 2")
            ]
        )
        
        uploads.append(contentsOf: [mockUpload1, mockUpload2])
        saveUploads()
    }
}