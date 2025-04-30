import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @AppStorage("selectedLanguage") private var selectedLanguageRawValue: String = Language.tr.rawValue
    
    @Published private(set) var currentLanguage: Language = .tr
    
    private init() {
        // Mevcut dil değerini AppStorage'dan al
        if let savedLanguage = Language(rawValue: selectedLanguageRawValue) {
            currentLanguage = savedLanguage
        }
    }
    
    func changeLanguage(to newLanguage: Language) {
        guard newLanguage != currentLanguage else { return }
        
        currentLanguage = newLanguage
        selectedLanguageRawValue = newLanguage.rawValue
        
        // Tüm uygulamaya dil değişikliğini bildir
        NotificationCenter.default.post(name: NSNotification.Name("LanguageDidChange"), object: nil)
    }
    
    func localizedString(_ key: String) -> String {
        let bundle = Bundle.main
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: "", comment: "")
    }
} 