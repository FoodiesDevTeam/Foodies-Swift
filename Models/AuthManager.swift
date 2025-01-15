import Foundation
import RealmSwift

class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var error: Error?
    @Published var isAuthenticated = false
    
    private let realmManager: RealmManager
    
    init(realmManager: RealmManager) {
        self.realmManager = realmManager
    }
    
    func signUp(username: String, email: String, password: String) {
        // Email formatı kontrolü
        guard isValidEmail(email) else {
            self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz email formatı"])
            return
        }
        
        // Şifre uzunluğu kontrolü
        guard password.count >= 6 else {
            self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Şifre en az 6 karakter olmalıdır"])
            return
        }
        
        // Kullanıcı zaten var mı kontrolü
        if realmManager.getUser(email: email) != nil {
            self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bu email adresi zaten kayıtlı"])
            return
        }
        
        // Yeni kullanıcı oluştur
        let newUser = User(username: username, email: email, password: password)
        realmManager.saveUser(newUser)
        
        // Otomatik giriş yap
        signIn(email: email, password: password)
    }
    
    func signIn(email: String, password: String) {
        guard let user = realmManager.getUser(email: email) else {
            self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bulunamadı"])
            return
        }
        
        if user.password == password {
            self.currentUser = user
            self.isAuthenticated = true
        } else {
            self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Hatalı şifre"])
        }
    }
    
    func signOut() {
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
} 
