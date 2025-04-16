import Foundation
import Supabase
import Auth

// MARK: - User Model
struct AppUser: Codable {
    let id: UUID
    let email: String
    var username: String
    var avatarURL: String?
    var bio: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(from supabaseUser: Auth.User) {
        self.id = supabaseUser.id
        self.email = supabaseUser.email ?? ""
        self.username = supabaseUser.email?.components(separatedBy: "@").first ?? ""
        self.avatarURL = nil
        self.bio = nil
        self.createdAt = supabaseUser.createdAt
        self.updatedAt = supabaseUser.updatedAt
    }
    
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

class AuthService: BaseSupabaseService {
    
    override required init(client: SupabaseClient) {
        super.init(client: client)
    }
    
    func signUp(email: String, password: String) async throws -> AppUser {
        var authUser: Auth.User?
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            
            authUser = try await client.auth.user()
            print("✅ Auth kullanıcısı oluşturuldu: \(authUser!.id)")
            
            let username = email.components(separatedBy: "@").first ?? ""
            
            let userData: [String: AnyJSON] = [
                "id": .string(authUser!.id.uuidString),
                "email": .string(email),
                "username": .string(username)
            ]
            
            try await client.database
                .from("users")
                .insert(userData)
                .execute()
            
            print("✅ Public users tablosuna kayıt başarılı. User ID: \(authUser!.id)")
            
            // UserDefaults için yeni User oluştur
            let newUserDefaults = UserDefaultsManager.shared.createUser(username: username)
            print("✅ UserDefaults için yeni User oluşturuldu: \(newUserDefaults.username)")
            
            // Mevcut kullanıcıyı ayarla
            UserDefaultsManager.shared.setCurrentUser(username: username)
            print("✅ Mevcut kullanıcı UserDefaults'a ayarlandı: \(username)")
            
            let appUser = AppUser(from: authUser!)
            return appUser
            
        } catch let insertError {
            print("❌ Public users tablosuna kayıt başarısız: \(insertError)")
            UserDefaultsManager.shared.setCurrentUser(username: nil)
            throw SupabaseError.clientError("Kullanıcı profili oluşturulamadı: \(insertError.localizedDescription)")
            
        } catch let authError as AuthError {
            print("❌ Auth kaydı başarısız: \(authError.message)")
            UserDefaultsManager.shared.setCurrentUser(username: nil)
            if authError.message.contains("User already registered") {
                throw SupabaseError.userAlreadyExists
            }
            throw SupabaseError.signUpFailed
        } catch {
            print("❌ Bilinmeyen hata: \(error)")
            UserDefaultsManager.shared.setCurrentUser(username: nil)
            throw SupabaseError.signUpFailed
        }
    }
    
    func signIn(email: String, password: String) async throws -> AppUser {
        do {
            let response = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            do {
                let user = try await client.auth.user()
                let appUser = AppUser(from: user)
                
                let username = email.components(separatedBy: "@").first ?? ""
                
                // UserDefaults'ta kullanıcı kontrolü ve oluşturma
                if UserDefaultsManager.shared.getUser(username: username) == nil {
                    _ = UserDefaultsManager.shared.createUser(username: username)
                    print("✅ UserDefaults için yeni User oluşturuldu: \(username)")
                } else {
                    print("ℹ️ Kullanıcı zaten UserDefaults'ta mevcut: \(username)")
                }
                
                // Mevcut kullanıcıyı ayarla
                UserDefaultsManager.shared.setCurrentUser(username: username)
                print("✅ Mevcut kullanıcı UserDefaults'a ayarlandı: \(username)")
                
                return appUser
            } catch {
                print("❌ Kullanıcı bilgisi alınamadı: \(error)")
                UserDefaultsManager.shared.setCurrentUser(username: nil)
                throw SupabaseError.signInFailed
            }
        } catch {
            print("❌ Giriş başarısız: \(error)")
            UserDefaultsManager.shared.setCurrentUser(username: nil)
            throw SupabaseError.signInFailed
        }
    }
    
    func signOut() async throws {
        do {
            try await client.auth.signOut()
            UserDefaultsManager.shared.setCurrentUser(username: nil)
            print("✅ Mevcut kullanıcı UserDefaults'tan temizlendi")
        } catch {
            print("❌ Çıkış başarısız: \(error)")
            throw SupabaseError.signOutFailed
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            print("🚫 Reset password failed: \(error)")
            throw SupabaseError.resetPasswordFailed
        }
    }
    
    func getCurrentUser() async throws -> AppUser? {
        do {
            do {
                // Supabase User tipini kullanarak yeni bir AppUser oluştur
                let user = try await client.auth.user()
                let appUser = AppUser(from: user)
                return appUser
            } catch {
                return nil
            }
        } catch {
            print("🚫 Get current user failed: \(error)")
            return nil
        }
    }
    
    func updateUserProfile(userId: UUID, username: String?, avatarURL: String?, bio: String?) async throws -> AppUser {
        do {
            // Veritabanında kullanıcı adı "full_name" olarak saklanıyor
            // Ancak uygulama içinde "username" olarak kullanılıyor
            // Encodable struct kullanacağımız için updateData değişkenine gerek yok
            
            // Encodable uyumlu bir struct oluştur
            struct UserUpdateData: Encodable {
                let full_name: String
                let avatar_url: String?
                let bio: String?
                
                init(username: String, avatarURL: String?, bio: String?) {
                    self.full_name = username
                    self.avatar_url = avatarURL
                    self.bio = bio
                }
            }
            
            // Encodable veri yapısı oluştur
            let encodableData = UserUpdateData(username: username ?? "", avatarURL: avatarURL, bio: bio)
            
            let response = try await client
                .database
                .from("users")
                .update(encodableData)
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
            
            if let responseData = response.data as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: responseData)
                let user = try AppUser.decoder.decode(AppUser.self, from: jsonData)
                return user
            } else {
                throw SupabaseError.dataError
            }
        } catch {
            print("🚫 Update user profile failed: \(error)")
            throw SupabaseError.clientError("Kullanıcı profili güncellenirken bir hata oluştu: \(error.localizedDescription)")
        }
    }
}
