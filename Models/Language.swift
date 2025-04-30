import Foundation

enum Language: String, CaseIterable {
    case en = "en"
    case tr = "tr"
    
    var displayName: String {
        switch self {
        case .en: return NSLocalizedString("english", comment: "English language name")
        case .tr: return NSLocalizedString("turkish", comment: "Turkish language name")
        }
    }
    
    var locale: Locale {
        return Locale(identifier: self.rawValue)
    }
} 