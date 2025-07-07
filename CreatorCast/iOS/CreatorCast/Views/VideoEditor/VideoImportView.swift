import SwiftUI
import PhotosUI
import AVFoundation

struct VideoImportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var videoService: VideoService
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var importedVideos: [Video] = []
    @State private var isImporting = false
    
    let onVideoSelected: ((Video) -> Void)?
    
    init(onVideoSelected: ((Video) -> Void)? = nil) {
        self.onVideoSelected = onVideoSelected
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Import Options
                VStack(spacing: 16) {
                    Text("Import Video")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Select a video to start editing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Photo Library
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 1,
                        matching: .videos
                    ) {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            Text("Choose from Photo Library")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            Text("Select videos from your device")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Cloud Storage (Future Implementation)
                    VStack(spacing: 12) {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("Import from Cloud")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("iCloud Drive, Google Drive (Coming Soon)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                if isImporting {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Importing video...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Recently Imported
                if !importedVideos.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recently Imported")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(importedVideos) { video in
                                    VideoThumbnailCard(video: video) {
                                        selectVideo(video)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
                
                Spacer()
            }
            .navigationTitle("Import Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedItems) { items in
            importVideos(from: items)
        }
        .onAppear {
            importedVideos = videoService.recentVideos
        }
    }
    
    private func importVideos(from items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        
        isImporting = true
        
        for item in items {
            item.loadTransferable(type: VideoTransferrable.self) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let videoTransferrable):
                        if let videoTransferrable = videoTransferrable {
                            processImportedVideo(url: videoTransferrable.url)
                        }
                    case .failure(let error):
                        print("Failed to import video: \(error)")
                    }
                    isImporting = false
                }
            }
        }
    }
    
    private func processImportedVideo(url: URL) {
        videoService.importVideo(from: url) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let video):
                    importedVideos.insert(video, at: 0)
                    selectVideo(video)
                case .failure(let error):
                    print("Failed to process video: \(error)")
                }
            }
        }
    }
    
    private func selectVideo(_ video: Video) {
        onVideoSelected?(video)
        dismiss()
    }
}

struct VideoThumbnailCard: View {
    let video: Video
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(9/16, contentMode: .fit)
                    .frame(width: 80)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    )
                
                Text(video.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .frame(width: 80, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

struct VideoTransferrable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "imported_video_\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

#Preview {
    VideoImportView()
        .environmentObject(VideoService.shared)
}