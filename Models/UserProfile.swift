import Foundation
import RealmSwift

class UserProfile: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var username: String = ""
    @Persisted var email: String = ""
    @Persisted var firstName: String = ""
    @Persisted var lastName: String = ""
    @Persisted var birthDate: Date = Date()
    @Persisted var gender: String = ""
    @Persisted var city: String = ""
    @Persisted var occupation: String = ""
    @Persisted var smokes: Bool = false
    @Persisted var drinksAlcohol: Bool = false
    @Persisted var foodPreferences: List<String>
    @Persisted var hobbies: List<String>
    @Persisted var smokingPreference: Bool = false
    @Persisted var drinkingPreference: Bool = false
    @Persisted var appPurpose: String = ""
    @Persisted var preferredGender: String = ""
    @Persisted var bio: String = ""
    @Persisted var photoUrls: List<String>
    
    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }
}

// MARK: - Enums for Selection Options
enum Gender: String, CaseIterable {
    case male = "Erkek"
    case female = "Kadın"
    case other = "Diğer"
}

enum AppPurpose: String, CaseIterable {
    case dating = "Flört etmek"
    case friendship = "Arkadaş edinmek"
    case diningCompanion = "Yemek yerken sohbet edicek birini bulmak"
    case business = "İş konuşmak için birini bulmak"
}

enum PreferredGender: String, CaseIterable {
    case any = "Önemli değil"
    case male = "Erkek"
    case female = "Kadın"
}
