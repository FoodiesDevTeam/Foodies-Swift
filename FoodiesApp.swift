import SwiftUI

@main
struct FoodiesApp: App {
    @StateObject private var languageManager = LanguageManager.shared
    
    init() {
        // Sadece test kullanıcısını sil
        UserDefaultsManager.shared.removeUser(username: "Mustafa Burma")
        UserDefaultsManager.shared.removeUser(username: "Musti Burma")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager)
                .environment(\.locale, Locale(identifier: languageManager.currentLanguage.rawValue))
                .id(languageManager.currentLanguage)
        }
    }
}