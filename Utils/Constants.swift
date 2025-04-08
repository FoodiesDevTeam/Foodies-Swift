import SwiftUI

enum Constants {
    enum Design {
        static let mainGradient = LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let cornerRadius: CGFloat = 12
        static let defaultPadding: CGFloat = 20
        static let defaultSpacing: CGFloat = 30
    }
    
    enum ImageSizes {
        static let logoSize: CGFloat = 200
    }
    
    enum FontSizes {
        static let title1: CGFloat = 40
        static let title2: CGFloat = 32
        static let body: CGFloat = 16
    }
    
    enum NotificationNames {
        static let userDidLogout = Notification.Name("UserDidLogout")
    }
} 