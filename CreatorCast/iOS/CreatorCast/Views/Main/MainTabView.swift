import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            VideoEditorView()
                .tabItem {
                    Image(systemName: "scissors")
                    Text("Edit")
                }
                .tag(1)
            
            UploadManagerView()
                .tabItem {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("Upload")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService.shared)
        .environmentObject(VideoService.shared)
        .environmentObject(UploadService.shared)
}