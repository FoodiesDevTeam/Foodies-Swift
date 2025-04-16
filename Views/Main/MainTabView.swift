import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                MatchView()
            }
            .tabItem {
                Image(systemName: "flame.fill")
                Text("Eşleşmeler")
            }
            .tag(0)
            
            NavigationView {
                ChatView()
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Mesajlar")
            }
            .tag(1)
            
            NavigationView {
                MatchesView()
            }
            .tabItem {
                Image(systemName: "person.2.fill")
                Text("Matchlerim")
            }
            .tag(2)
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profil")
            }
            .tag(3)
        }
        .accentColor(Color .pink)
    }
}
