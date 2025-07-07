import SwiftUI
import AVFoundation

struct VideoEditorView: View {
    @EnvironmentObject var videoService: VideoService
    @State private var selectedVideo: Video?
    @State private var showVideoImport = false
    @State private var showUploadView = false
    @State private var editSettings = VideoEditSettings()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let video = selectedVideo {
                    // Video Preview
                    VideoPreviewView(video: video, editSettings: $editSettings)
                        .frame(maxHeight: 400)
                    
                    // Editing Tools
                    EditingToolsView(video: video, editSettings: $editSettings)
                        .frame(maxHeight: 200)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button("Save Draft") {
                            saveVideoEdits()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Upload") {
                            showUploadView = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(video.uploadStatus != .ready)
                    }
                    .padding()
                } else {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "scissors")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Video Selected")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Import a video to start editing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Import Video") {
                            showVideoImport = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Video Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        showVideoImport = true
                    }
                }
            }
        }
        .sheet(isPresented: $showVideoImport) {
            VideoImportView { video in
                selectedVideo = video
            }
        }
        .sheet(isPresented: $showUploadView) {
            if let video = selectedVideo {
                UploadSelectionView(video: video)
            }
        }
        .onAppear {
            if let recentVideo = videoService.recentVideos.first {
                selectedVideo = recentVideo
            }
        }
    }
    
    private func saveVideoEdits() {
        guard let video = selectedVideo else { return }
        
        // Apply edits to video
        videoService.applyEdits(to: video, settings: editSettings) { success in
            if success {
                // Update UI
                print("Video edits saved successfully")
            } else {
                print("Failed to save video edits")
            }
        }
    }
}

#Preview {
    VideoEditorView()
        .environmentObject(VideoService.shared)
}