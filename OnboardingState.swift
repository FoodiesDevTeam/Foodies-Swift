import Foundation

enum OnboardingState: Int, CaseIterable {
    case personalInfo = 0
    case hobbiesFood
    case matchingPreferences
    case photoBio
    
    var title: String {
        switch self {
        case .personalInfo:
            return "Kişisel Bilgiler"
        case .hobbiesFood:
            return "Hobiler ve Yemek Zevkleri"
        case .matchingPreferences:
            return "Eşleşme Tercihleri"
        case .photoBio:
            return "Fotoğraf ve Bio"
        }
    }
    
    var progress: Double {
        return Double(self.rawValue + 1) / Double(OnboardingState.allCases.count)
    }
} 