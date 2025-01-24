import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                MatchView(matchType: .bestMatch)
            }
            .tabItem {
                Image(systemName: "flame.fill")
                Text("Best Match")
            }
            .tag(0)
            
            NavigationView {
                CloseToYouView()
            }
            .tabItem {
                Image(systemName: "location.fill")
                Text("Close To You")
            }
            .tag(1)
            
            NavigationView {
                Text("Messages")
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Messages")
            }
            .tag(2)
            
            NavigationView {
                Text("Profile")
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
            .tag(3)
        }
        .accentColor(.purple)
    }
}
