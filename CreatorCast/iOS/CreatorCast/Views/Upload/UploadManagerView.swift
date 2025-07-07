import SwiftUI

struct UploadManagerView: View {
    @EnvironmentObject var uploadService: UploadService
    @State private var selectedFilter: UploadFilter = .all
    
    enum UploadFilter: String, CaseIterable {
        case all = "All"
        case uploading = "Uploading"
        case completed = "Completed"
        case failed = "Failed"
        case scheduled = "Scheduled"
    }
    
    var filteredUploads: [Upload] {
        switch selectedFilter {
        case .all:
            return uploadService.uploads
        case .uploading:
            return uploadService.uploads.filter { $0.status == .uploading || $0.status == .processing }
        case .completed:
            return uploadService.uploads.filter { $0.status == .completed }
        case .failed:
            return uploadService.uploads.filter { $0.status == .failed }
        case .scheduled:
            return uploadService.uploads.filter { $0.status == .scheduled }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Segment
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(UploadFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Upload List
                if filteredUploads.isEmpty {
                    EmptyUploadState(filter: selectedFilter)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredUploads) { upload in
                                UploadCard(upload: upload)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Uploads")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        uploadService.clearCompletedUploads()
                    }
                    .disabled(uploadService.uploads.filter { $0.status == .completed }.isEmpty)
                }
            }
        }
        .refreshable {
            await uploadService.refreshUploads()
        }
    }
}

struct EmptyUploadState: View {
    let filter: UploadManagerView.UploadFilter
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyStateIcon: String {
        switch filter {
        case .all:
            return "arrow.up.circle"
        case .uploading:
            return "arrow.up.circle.fill"
        case .completed:
            return "checkmark.circle"
        case .failed:
            return "xmark.circle"
        case .scheduled:
            return "clock.circle"
        }
    }
    
    private var emptyStateTitle: String {
        switch filter {
        case .all:
            return "No Uploads"
        case .uploading:
            return "No Active Uploads"
        case .completed:
            return "No Completed Uploads"
        case .failed:
            return "No Failed Uploads"
        case .scheduled:
            return "No Scheduled Uploads"
        }
    }
    
    private var emptyStateMessage: String {
        switch filter {
        case .all:
            return "Start by editing a video and selecting platforms to upload to."
        case .uploading:
            return "No uploads are currently in progress."
        case .completed:
            return "Completed uploads will appear here."
        case .failed:
            return "Failed uploads will appear here for retry."
        case .scheduled:
            return "Scheduled uploads will appear here."
        }
    }
}

struct UploadCard: View {
    @EnvironmentObject var uploadService: UploadService
    @EnvironmentObject var videoService: VideoService
    let upload: Upload
    
    @State private var showRetryAlert = false
    @State private var showCancelAlert = false
    
    var video: Video? {
        videoService.getVideo(id: upload.videoId)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(video?.title ?? "Unknown Video")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(upload.status.displayName)
                        .font(.subheadline)
                        .foregroundColor(upload.status.color)
                }
                
                Spacer()
                
                // Status Icon
                Image(systemName: upload.status.icon)
                    .font(.system(size: 20))
                    .foregroundColor(upload.status.color)
            }
            
            // Progress Bar (for uploading)
            if upload.status == .uploading || upload.status == .processing {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: upload.progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("\(Int(upload.progress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Platforms
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(upload.platformConfigs) { config in
                        PlatformBadge(platform: config.platform)
                    }
                }
                .padding(.horizontal, 1)
            }
            
            // Error Message
            if let error = upload.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(2)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
            
            // Actions
            HStack {
                if upload.status == .failed {
                    Button("Retry") {
                        retryUpload()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.blue)
                }
                
                if upload.status == .uploading || upload.status == .processing || upload.status == .scheduled {
                    Button("Cancel") {
                        showCancelAlert = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                
                Spacer()
                
                if upload.status == .completed {
                    Button("View Results") {
                        viewUploadResults()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Retry Upload", isPresented: $showRetryAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Retry") {
                retryUpload()
            }
        } message: {
            Text("This will retry the upload to all selected platforms.")
        }
        .alert("Cancel Upload", isPresented: $showCancelAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Stop Upload", role: .destructive) {
                cancelUpload()
            }
        } message: {
            Text("This will cancel the upload and cannot be undone.")
        }
    }
    
    private func retryUpload() {
        uploadService.retryUpload(upload)
    }
    
    private func cancelUpload() {
        uploadService.cancelUpload(upload)
    }
    
    private func viewUploadResults() {
        // TODO: Navigate to results view
        print("View results for upload: \(upload.id)")
    }
}

struct PlatformBadge: View {
    let platform: Platform
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: platform.icon)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: platform.color))
            
            Text(platform.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: platform.color).opacity(0.1))
        .cornerRadius(8)
    }
}

extension Upload.UploadStatus {
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .uploading:
            return "Uploading"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        case .scheduled:
            return "Scheduled"
        }
    }
    
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .processing:
            return .blue
        case .uploading:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        case .scheduled:
            return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .processing:
            return "gearshape.fill"
        case .uploading:
            return "arrow.up.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .cancelled:
            return "stop.circle.fill"
        case .scheduled:
            return "calendar.circle.fill"
        }
    }
}

#Preview {
    UploadManagerView()
        .environmentObject(UploadService.shared)
        .environmentObject(VideoService.shared)
}