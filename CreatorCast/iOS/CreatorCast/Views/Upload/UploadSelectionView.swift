import SwiftUI

struct UploadSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var uploadService: UploadService
    @State private var selectedPlatforms: Set<Platform> = []
    @State private var platformConfigs: [Platform: PlatformUploadConfig] = [:]
    @State private var isUploading = false
    @State private var showScheduler = false
    
    let video: Video
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Video Preview
                VStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(video.aspectRatio.cgSize, contentMode: .fit)
                        .frame(maxHeight: 120)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        )
                    
                    Text(video.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                }
                .padding()
                
                Divider()
                
                // Platform Selection
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Platform.allCases) { platform in
                            PlatformSelectionCard(
                                platform: platform,
                                video: video,
                                isSelected: selectedPlatforms.contains(platform),
                                config: platformConfigs[platform] ?? PlatformUploadConfig(platform: platform, title: video.title, description: video.description)
                            ) { isSelected, config in
                                if isSelected {
                                    selectedPlatforms.insert(platform)
                                    platformConfigs[platform] = config
                                } else {
                                    selectedPlatforms.remove(platform)
                                    platformConfigs.removeValue(forKey: platform)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Button("Schedule") {
                            showScheduler = true
                        }
                        .buttonStyle(.bordered)
                        .disabled(selectedPlatforms.isEmpty)
                        
                        Button("Upload Now") {
                            startUpload()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedPlatforms.isEmpty || isUploading)
                    }
                    
                    if isUploading {
                        ProgressView("Preparing upload...")
                            .scaleEffect(0.8)
                    }
                }
                .padding()
            }
            .navigationTitle("Select Platforms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showScheduler) {
            ScheduleUploadView(
                video: video,
                platformConfigs: Array(platformConfigs.values)
            )
        }
    }
    
    private func startUpload() {
        isUploading = true
        
        let configs = Array(platformConfigs.values)
        let upload = Upload(videoId: video.id, platformConfigs: configs)
        
        uploadService.startUpload(upload) { success in
            DispatchQueue.main.async {
                isUploading = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

struct PlatformSelectionCard: View {
    let platform: Platform
    let video: Video
    let isSelected: Bool
    let config: PlatformUploadConfig
    let onSelectionChanged: (Bool, PlatformUploadConfig) -> Void
    
    @State private var localConfig: PlatformUploadConfig
    @State private var showConfig = false
    
    init(platform: Platform, video: Video, isSelected: Bool, config: PlatformUploadConfig, onSelectionChanged: @escaping (Bool, PlatformUploadConfig) -> Void) {
        self.platform = platform
        self.video = video
        self.isSelected = isSelected
        self.config = config
        self.onSelectionChanged = onSelectionChanged
        self._localConfig = State(initialValue: config)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Platform Info
                HStack(spacing: 12) {
                    Image(systemName: platform.icon)
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: platform.color))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(platform.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Max: \(Int(platform.maxDuration))s • \(platform.maxFileSize / (1024 * 1024))MB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Selection Toggle
                Button(action: {
                    let newSelection = !isSelected
                    onSelectionChanged(newSelection, localConfig)
                }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .blue : .gray)
                }
            }
            
            // Platform-specific warnings
            if !isPlatformCompatible() {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text(getCompatibilityWarning())
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
            
            // Configuration Button
            if isSelected {
                Button("Configure Upload") {
                    showConfig = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .sheet(isPresented: $showConfig) {
            PlatformConfigView(
                platform: platform,
                config: $localConfig
            ) { updatedConfig in
                onSelectionChanged(isSelected, updatedConfig)
            }
        }
    }
    
    private func isPlatformCompatible() -> Bool {
        return video.duration <= platform.maxDuration &&
               video.fileSize <= platform.maxFileSize &&
               platform.supportedAspectRatios.contains(video.aspectRatio)
    }
    
    private func getCompatibilityWarning() -> String {
        var warnings: [String] = []
        
        if video.duration > platform.maxDuration {
            warnings.append("Video too long")
        }
        
        if video.fileSize > platform.maxFileSize {
            warnings.append("File too large")
        }
        
        if !platform.supportedAspectRatios.contains(video.aspectRatio) {
            warnings.append("Unsupported aspect ratio")
        }
        
        return warnings.joined(separator: ", ")
    }
}

struct ScheduleUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scheduledDate = Date()
    @State private var scheduledTime = Date()
    
    let video: Video
    let platformConfigs: [PlatformUploadConfig]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Schedule Upload")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose when to publish your video")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    DatePicker("Date", selection: $scheduledDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    
                    DatePicker("Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Selected Platforms")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(platformConfigs) { config in
                        HStack {
                            Image(systemName: config.platform.icon)
                                .foregroundColor(Color(hex: config.platform.color))
                            
                            Text(config.platform.displayName)
                                .font(.subheadline)
                            
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                Button("Schedule Upload") {
                    scheduleUpload()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func scheduleUpload() {
        // Combine date and time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: scheduledDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        let finalDate = calendar.date(from: combinedComponents) ?? Date()
        
        // TODO: Schedule upload with final date
        print("Scheduling upload for: \(finalDate)")
        
        dismiss()
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    UploadSelectionView(video: Video(
        id: "test",
        title: "Test Video",
        description: "Test Description",
        localURL: URL(string: "file://test.mov")!,
        thumbnailURL: nil,
        duration: 30,
        aspectRatio: .vertical,
        fileSize: 1024 * 1024,
        createdAt: Date(),
        editedAt: nil,
        uploadStatus: .ready
    ))
    .environmentObject(UploadService.shared)
}