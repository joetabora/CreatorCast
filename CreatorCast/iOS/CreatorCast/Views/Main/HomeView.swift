import SwiftUI

struct HomeView: View {
    @EnvironmentObject var videoService: VideoService
    @State private var showVideoImport = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 16) {
                            QuickActionButton(
                                icon: "video.fill",
                                title: "Import Video",
                                color: .blue
                            ) {
                                showVideoImport = true
                            }
                            
                            QuickActionButton(
                                icon: "scissors",
                                title: "Edit Video",
                                color: .green
                            ) {
                                // Navigate to video editor
                            }
                            
                            QuickActionButton(
                                icon: "arrow.up.circle.fill",
                                title: "Upload",
                                color: .orange
                            ) {
                                // Navigate to upload manager
                            }
                        }
                    }
                    
                    // Recent Videos
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Videos")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if videoService.recentVideos.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "video.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                
                                Text("No videos yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Button("Import Your First Video") {
                                    showVideoImport = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(videoService.recentVideos) { video in
                                    VideoThumbnailView(video: video)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("CreatorCast")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showVideoImport) {
            VideoImportView()
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .cornerRadius(12)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct VideoThumbnailView: View {
    let video: Video
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(9/16, contentMode: .fit)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                )
            
            Text(video.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(VideoService.shared)
}