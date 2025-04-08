import Foundation

enum OnboardingState: Int, CaseIterable {
    case personalInfo = 0
    case preferences
    case photoBio
    case hobbiesFood
    case matchingPreferences
    
    var title: String {
        switch self {
        case .personalInfo:
            return "Kişisel Bilgiler"
        case .preferences:
            return "Eşleşme Tercihleri"
        case .photoBio:
            return "Fotoğraf ve Bio"
        case .hobbiesFood:
            return "Hobiler ve Yemek Zevkleri"
        case .matchingPreferences:
            return "Eşleşme Kriterleri"
        }
    }
    
    var progress: Double {
        return Double(self.rawValue + 1) / Double(OnboardingState.allCases.count)
    }
} 