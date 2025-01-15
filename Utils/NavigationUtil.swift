import SwiftUI

enum NavigationUtil {
    static func navigate<V: View>(to view: V) {
        if let window = UIApplication.shared.windows.first {
            window.rootViewController = UIHostingController(rootView: view)
            window.makeKeyAndVisible()
        }
    }
}
