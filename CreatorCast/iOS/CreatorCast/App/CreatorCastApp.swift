import SwiftUI
import Firebase

@main
struct CreatorCastApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthService.shared)
                .environmentObject(VideoService.shared)
                .environmentObject(UploadService.shared)
        }
    }
}