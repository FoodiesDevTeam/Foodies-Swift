import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showMatchRequests = false
    @State private var pendingRequests: [MatchRequest] = []
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Ana Sayfa
            NavigationView {
                MatchView()
            }
            .tabItem {
                Image(systemName: "heart.fill")
                Text("Ana Sayfa")
            }
            .tag(0)
            
            // Eşleşmeler
            NavigationView {
                MatchesView()
            }
            .tabItem {
                Image(systemName: "person.2.fill")
                Text("Eşleşmeler")
            }
            .tag(1)
            
            // Mesajlar
            NavigationView {
                ChatView()
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Mesajlar")
            }
            .tag(2)
            
            // Profil
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profil")
            }
            .tag(3)
        }
        .onAppear {
            loadPendingRequests()
        }
    }
    
    private func loadPendingRequests() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            pendingRequests = UserDefaultsManager.shared.getPendingMatchRequests(for: currentUser.username)
        }
    }
}
