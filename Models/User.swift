import Foundation
import RealmSwift

class User: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var username: String = ""
    @Persisted var email: String = ""
    @Persisted var password: String = "" // Gerçek uygulamada şifreleri hash'lemeyi unutmayın
    
    convenience init(username: String, email: String, password: String) {
        self.init()
        self.username = username
        self.email = email
        self.password = password
    }
} 