import Foundation

class LanguageManager {
    static let shared = LanguageManager()
    
    enum Language: String {
        case english = "en"
        case turkish = "tr"
    }
    
    private let languageKey = "selectedLanguage"
    
    var currentLanguage: Language {
        get {
            if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
               let language = Language(rawValue: savedLanguage) {
                return language
            }
            return .english // Default language
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
            NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
        }
    }
    
    private init() {}
    
    func localizedString(_ key: String) -> String {
        switch currentLanguage {
        case .english:
            return englishStrings[key] ?? key
        case .turkish:
            return turkishStrings[key] ?? key
        }
    }
    
    // English translations
    private let englishStrings: [String: String] = [
        "profile": "Profile",
        "settings": "Settings",
        "language": "Language",
        "english": "English",
        "turkish": "Turkish",
        "logout": "Logout",
        "close": "Close",
        "years": "years old",
        "editProfile": "Edit Profile",
        "save": "Save",
        "cancel": "Cancel"
    ]
    
    // Turkish translations
    private let turkishStrings: [String: String] = [
        "profile": "Profil",
        "settings": "Ayarlar",
        "language": "Dil",
        "english": "İngilizce",
        "turkish": "Türkçe",
        "logout": "Çıkış Yap",
        "close": "Kapat",
        "years": "yaşında",
        "editProfile": "Profili Düzenle",
        "save": "Kaydet",
        "cancel": "İptal"
    ]
} 