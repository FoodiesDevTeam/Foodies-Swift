import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
#if canImport(UIKit)
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            // Seçili ikon/text rengi: sabit pembe
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemPink
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemPink]
            // Seçili olmayan ikon/text rengi
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
#endif
            loadPendingRequests()
        }
    }
    
    private func loadPendingRequests() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            pendingRequests = UserDefaultsManager.shared.getPendingMatchRequests(for: currentUser.username)
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
