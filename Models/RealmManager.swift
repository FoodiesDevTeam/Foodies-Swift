import Foundation
import RealmSwift

class RealmManager: ObservableObject {
    private var realm: Realm?
    @Published var error: Error?
    
    init() {
        initializeRealm()
    }
    
    private func initializeRealm() {
        do {
            let config = Realm.Configuration(
                schemaVersion: 1,
                migrationBlock: { migration, oldSchemaVersion in
                    if oldSchemaVersion < 1 {
                        // Şema değişikliklerini burada yapılandırın
                    }
                }
            )
            
            Realm.Configuration.defaultConfiguration = config
            realm = try Realm()
            
            print("Realm başarıyla başlatıldı")
            print("Realm dosya konumu: \(Realm.Configuration.defaultConfiguration.fileURL?.path ?? "")")
            
        } catch {
            self.error = error
            print("Realm başlatma hatası: \(error)")
        }
    }
    
    // CRUD İşlemleri
    func saveUser(_ user: User) {
        do {
            guard let realm = realm else { return }
            try realm.write {
                realm.add(user)
            }
        } catch {
            self.error = error
            print("Kullanıcı kaydetme hatası: \(error)")
        }
    }
    
    func getUser(email: String) -> User? {
        guard let realm = realm else { return nil }
        return realm.objects(User.self).filter("email == %@", email).first
    }
    
    func updateUser(_ user: User) {
        do {
            guard let realm = realm else { return }
            try realm.write {
                realm.add(user, update: .modified)
            }
        } catch {
            self.error = error
            print("Kullanıcı güncelleme hatası: \(error)")
        }
    }
    
    func deleteUser(_ user: User) {
        do {
            guard let realm = realm else { return }
            try realm.write {
                realm.delete(user)
            }
        } catch {
            self.error = error
            print("Kullanıcı silme hatası: \(error)")
        }
    }
} 