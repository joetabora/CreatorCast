import Foundation
import AVFoundation
import Combine

class VideoService: ObservableObject {
    static let shared = VideoService()
    
    @Published var recentVideos: [Video] = []
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    init() {
        loadRecentVideos()
    }
    
    // MARK: - Video Import
    
    func importVideo(from url: URL, completion: @escaping (Result<Video, Error>) -> Void) {
        isProcessing = true
        processingProgress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let asset = AVAsset(url: url)
                let duration = try await asset.load(.duration)
                
                // Copy video to documents directory
                let videoId = UUID().uuidString
                let destinationURL = self?.documentsDirectory.appendingPathComponent("\(videoId).mov")
                
                guard let destinationURL = destinationURL else {
                    DispatchQueue.main.async {
                        completion(.failure(VideoError.invalidDestination))
                    }
                    return
                }
                
                try FileManager.default.copyItem(at: url, to: destinationURL)
                
                // Generate thumbnail
                let thumbnailURL = try await self?.generateThumbnail(for: asset, videoId: videoId)
                
                // Get video metadata
                let naturalSize = try await asset.load(.naturalSize)
                let aspectRatio = self?.determineAspectRatio(size: naturalSize) ?? .vertical
                
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
                let fileSize = fileAttributes[.size] as? Int64 ?? 0
                
                let video = Video(
                    id: videoId,
                    title: "Imported Video \(Date().formatted(date: .omitted, time: .shortened))",
                    description: "",
                    localURL: destinationURL,
                    thumbnailURL: thumbnailURL,
                    duration: duration.seconds,
                    aspectRatio: aspectRatio,
                    fileSize: fileSize,
                    createdAt: Date(),
                    editedAt: nil,
                    uploadStatus: .draft
                )
                
                DispatchQueue.main.async {
                    self?.recentVideos.insert(video, at: 0)
                    self?.saveVideo(video)
                    self?.isProcessing = false
                    completion(.success(video))
                }
                
            } catch {
                DispatchQueue.main.async {
                    self?.isProcessing = false
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Video Editing
    
    func applyEdits(to video: Video, settings: VideoEditSettings, completion: @escaping (Bool) -> Void) {
        isProcessing = true
        processingProgress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let asset = AVAsset(url: video.localURL)
                let composition = AVMutableComposition()
                
                // Create video track
                guard let videoTrack = asset.tracks(withMediaType: .video).first,
                      let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                
                // Apply trimming
                let startTime = CMTime(seconds: settings.trimStart, preferredTimescale: 600)
                let endTime = settings.trimEnd > 0 ? CMTime(seconds: settings.trimEnd, preferredTimescale: 600) : asset.duration
                let timeRange = CMTimeRange(start: startTime, end: endTime)
                
                try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
                
                // Apply audio track if exists
                if let audioTrack = asset.tracks(withMediaType: .audio).first,
                   let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                    try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
                }
                
                // Export edited video
                let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
                let outputURL = self?.documentsDirectory.appendingPathComponent("edited_\(video.id).mov")
                
                exportSession?.outputURL = outputURL
                exportSession?.outputFileType = .mov
                
                exportSession?.exportAsynchronously {
                    DispatchQueue.main.async {
                        self?.isProcessing = false
                        completion(exportSession?.status == .completed)
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self?.isProcessing = false
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Video Management
    
    func getVideo(id: String) -> Video? {
        return recentVideos.first { $0.id == id }
    }
    
    func deleteVideo(_ video: Video) {
        // Remove from array
        recentVideos.removeAll { $0.id == video.id }
        
        // Delete files
        try? FileManager.default.removeItem(at: video.localURL)
        if let thumbnailURL = video.thumbnailURL {
            try? FileManager.default.removeItem(at: thumbnailURL)
        }
        
        // Remove from UserDefaults
        var savedVideos = getSavedVideos()
        savedVideos.removeAll { $0.id == video.id }
        saveVideos(savedVideos)
    }
    
    // MARK: - Private Methods
    
    private func generateThumbnail(for asset: AVAsset, videoId: String) async throws -> URL {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        let cgImage = try await imageGenerator.image(at: time).image
        
        let thumbnailURL = documentsDirectory.appendingPathComponent("\(videoId)_thumbnail.jpg")
        
        if let imageData = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.8) {
            try imageData.write(to: thumbnailURL)
            return thumbnailURL
        }
        
        throw VideoError.thumbnailGenerationFailed
    }
    
    private func determineAspectRatio(size: CGSize) -> Video.AspectRatio {
        let ratio = size.width / size.height
        
        if abs(ratio - 9.0/16.0) < 0.1 {
            return .vertical
        } else if abs(ratio - 1.0) < 0.1 {
            return .square
        } else {
            return .horizontal
        }
    }
    
    private func loadRecentVideos() {
        recentVideos = getSavedVideos()
    }
    
    private func saveVideo(_ video: Video) {
        var savedVideos = getSavedVideos()
        savedVideos.removeAll { $0.id == video.id }
        savedVideos.insert(video, at: 0)
        saveVideos(savedVideos)
    }
    
    private func getSavedVideos() -> [Video] {
        guard let data = UserDefaults.standard.data(forKey: "SavedVideos"),
              let videos = try? JSONDecoder().decode([Video].self, from: data) else {
            return []
        }
        return videos
    }
    
    private func saveVideos(_ videos: [Video]) {
        if let data = try? JSONEncoder().encode(videos) {
            UserDefaults.standard.set(data, forKey: "SavedVideos")
        }
    }
}

enum VideoError: Error {
    case invalidDestination
    case thumbnailGenerationFailed
    case exportFailed
    case invalidAsset
    
    var localizedDescription: String {
        switch self {
        case .invalidDestination:
            return "Invalid destination for video"
        case .thumbnailGenerationFailed:
            return "Failed to generate thumbnail"
        case .exportFailed:
            return "Failed to export video"
        case .invalidAsset:
            return "Invalid video asset"
        }
    }
}