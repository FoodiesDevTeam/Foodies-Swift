import SwiftUI

@main
struct FoodiesApp: App {
    let realmManager = RealmManager()
    @StateObject private var authManager: AuthManager
    
    init() {
        let realmManager = RealmManager()
        _authManager = StateObject(wrappedValue: AuthManager(realmManager: realmManager))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
} 