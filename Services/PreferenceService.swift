import Foundation
import Supabase


struct FoodPreference: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, category
        case createdAt = "created_at"
    }
    
    // Decoder'ı bir yerde merkezi tanımlamak daha iyi olabilir
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = formatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        return decoder
    }()
}

struct Hobby: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, category
        case createdAt = "created_at"
    }
    
    static let decoder: JSONDecoder = FoodPreference.decoder // Aynı decoder'ı kullan
}

struct UserPreferences: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static let decoder: JSONDecoder = FoodPreference.decoder // Aynı decoder'ı kullan
}

// Arayüz için kullanılanlar
struct FoodPreferenceNew: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name
        case createdAt = "created_at"
    }
    
    // Decode/Encode işlemleri için merkezi decoder kullanılabilir.
    // Eğer özel bir durum yoksa ayrıca tanımlamaya gerek yok.
}

struct HobbyNew: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name
        case createdAt = "created_at"
    }
}


// MARK: - Preference Service

class PreferenceService: BaseSupabaseService {
    // Bu sınıfın BaseSupabaseService'den miras aldığı ve
    // BaseSupabaseService'in bir 'client: SupabaseClient' özelliği sağladığı varsayılıyor.
    // Eğer 'client' hataları devam ederse, BaseSupabaseService'i kontrol etmelisiniz.

    // MARK: - Genel Tercih Listelerini Alma
    
    func getFoodPreferences() async throws -> [FoodPreferenceNew] {
        print("🍔 getFoodPreferences başlıyor")
        do {
            // Doğrudan .value kullanarak decode etmeyi dene
            let preferences: [FoodPreferenceNew] = try await client
                .database
                .from("food_preferences")
                .select("id, name, created_at") // Gerekli sütunları seç
                .execute()
                .value // Decode et [FoodPreferenceNew] olarak

            print("✅ Veritabanından \(preferences.count) yemek tercihi başarıyla çekildi ve decode edildi.")
            
            // Veritabanı boş olabilir, bu bir hata değil. Boş listeyi döndür.
            // if preferences.isEmpty {
            //     print("ℹ️ Veritabanında yemek tercihi bulunamadı (liste boş).")
            //     // Boş liste döndürmek genellikle bir hata değildir.
            //     // throw SupabaseError.dataError // Boş listeyi hata saymak istersen
            // }
            return preferences

        } catch let postgrestError as PostgrestError {
            print("🚫 getFoodPreferences - Postgrest Hatası: \(postgrestError)")
            print("📝 Hata Kodu: \(postgrestError.code ?? "Yok")")
            print("📝 Hata Mesajı: \(postgrestError.message ?? "Yok")")
            throw SupabaseError.clientError("Yemek tercihleri veritabanından alınamadı: \(postgrestError.message ?? "Bilinmeyen Postgrest Hatası")")
        } catch let decodingError as DecodingError {
             print("🚫 getFoodPreferences - Decode Hatası: \(decodingError)")
             // Decode hatası detaylarını logla
             // ... (detaylı loglama eklenebilir) ...
             throw SupabaseError.clientError("Yemek tercihleri verisi işlenemedi.")
        } catch {
            print("🚫 getFoodPreferences - Bilinmeyen Hata: \(error)")
            throw SupabaseError.clientError("Yemek tercihleri alınırken bilinmeyen bir hata oluştu: \(error.localizedDescription)")
        }
    }
        
    func getHobbies() async throws -> [HobbyNew] {
        print("🎾 getHobbies başlıyor")
        do {
            // Doğrudan .value kullanarak decode etmeyi dene
            let hobbies: [HobbyNew] = try await client
                .database
                .from("hobbies")
                .select("id, name, created_at") // Gerekli sütunları seç
                .execute()
                .value // Decode et [HobbyNew] olarak

            print("✅ Veritabanından \(hobbies.count) hobi başarıyla çekildi ve decode edildi.")
            
            // Boş liste hata değildir.
            // if hobbies.isEmpty {
            //     print("ℹ️ Veritabanında hobi bulunamadı (liste boş).")
            // }
            return hobbies

        } catch let postgrestError as PostgrestError {
            print("🚫 getHobbies - Postgrest Hatası: \(postgrestError)")
            print("📝 Hata Kodu: \(postgrestError.code ?? "Yok")")
            print("📝 Hata Mesajı: \(postgrestError.message ?? "Yok")")
            throw SupabaseError.clientError("Hobiler veritabanından alınamadı: \(postgrestError.message ?? "Bilinmeyen Postgrest Hatası")")
        } catch let decodingError as DecodingError {
             print("🚫 getHobbies - Decode Hatası: \(decodingError)")
             // ... (detaylı loglama eklenebilir) ...
             throw SupabaseError.clientError("Hobi verisi işlenemedi.")
        } catch {
            print("🚫 getHobbies - Bilinmeyen Hata: \(error)")
            throw SupabaseError.clientError("Hobiler alınırken bilinmeyen bir hata oluştu: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Kullanıcıya Özel Tercihleri Kaydetme (RPC)
    
    func saveUserPreferences(userId: UUID, foodPreferences: [UUID], hobbies: [UUID]) async throws {
        // Oturum ve kullanıcı ID kontrolleri
        guard let session = try? await client.auth.session else {
            print("🚫 Oturum bulunamadı (saveUserPreferences)")
            throw SupabaseError.sessionError
        }
        guard session.user.id == userId else {
            print("🚫 Kullanıcı kimliği eşleşmiyor (saveUserPreferences): \(session.user.id) != \(userId)")
            throw SupabaseError.userNotFound
        }
        
        print("💾 RPC fonksiyonu save_user_preferences_rpc çağrılıyor. Kullanıcı: \(userId)")
        
        // RPC fonksiyonuna gönderilecek parametreler
        struct RPCParams: Encodable {
            let p_user_id: UUID
            let p_food_preference_ids: [UUID]
            let p_hobby_ids: [UUID]
        }
        let params = RPCParams(
            p_user_id: userId,
            p_food_preference_ids: foodPreferences,
            p_hobby_ids: hobbies
        )
        
        do {
            // RPC fonksiyonunu çağır ve `.value` ile doğrudan UUID'yi decode et
            let preferenceId: UUID = try await client.database.rpc(
                "save_user_preferences_rpc",
                params: params
            )
            .execute()
            .value // UUID olarak decode etmeyi bekle
            
            print("✅ RPC save_user_preferences_rpc başarıyla tamamlandı. Dönen Preference ID: \(preferenceId)")
            print("🎉 Kullanıcı tercihleri başarıyla kaydedildi!")
            
        } catch let postgrestError as PostgrestError {
             print("🚫 RPC save_user_preferences_rpc çağrılırken Postgrest hatası: \(postgrestError)")
             print("📝 Hata Kodu: \(postgrestError.code ?? "Yok")")
             print("📝 Hata Mesajı: \(postgrestError.message ?? "Yok")")
             // 'detail' (tek L) PostgrestError'da bulunan bir özelliktir
             print("📝 Hata Detayı: \(postgrestError.detail ?? "Yok")")
             throw SupabaseError.clientError("Tercihler kaydedilirken veritabanı hatası oluştu: \(postgrestError.message ?? "Detay yok")")
        } catch let decodingError as DecodingError {
             print("🚫 RPC save_user_preferences_rpc yanıtı decode edilirken hata: \(decodingError)")
             // Decode hatası detaylarını logla
             // ... (detaylı loglama eklenebilir) ...
             throw SupabaseError.clientError("Veritabanı yanıtı işlenemedi (RPC).")
        } catch {
            print("🚫 RPC save_user_preferences_rpc çağrılırken bilinmeyen hata: \(error)")
            throw SupabaseError.clientError("Tercihler kaydedilirken bilinmeyen bir hata oluştu: \(error.localizedDescription)")
        }
    }

    // MARK: - Kullanıcıya Özel Tercihleri Alma
    
    func getUserPreferences(userId: UUID) async throws -> UserPreferences {
        print("👤 Kullanıcı tercihleri alınıyor: \(userId)")
        do {
            let preferences: UserPreferences = try await client
                .database
                .from("user_preferences")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value
            
            print("✅ Kullanıcı tercihleri başarıyla alındı")
            return preferences
            
        } catch let postgrestError as PostgrestError {
            print("🚫 getUserPreferences - Postgrest Hatası: \(postgrestError)")
            throw SupabaseError.clientError("Kullanıcı tercihleri yüklenirken hata: \(postgrestError.message ?? "Bilinmeyen hata")")
        } catch {
            print("🚫 getUserPreferences - Bilinmeyen Hata: \(error)")
            throw SupabaseError.clientError("Kullanıcı tercihleri yüklenirken hata: \(error.localizedDescription)")
        }
    }
    
    func getUserFoodPreferences(userPreferenceId: UUID) async throws -> [FoodPreferenceNew] {
        print("🍔 Seçili yemek tercihleri alınıyor: \(userPreferenceId)")
        do {
            struct ResultType: Decodable {
                let food_preferences: FoodPreferenceNew
            }
            
            let results: [ResultType] = try await client
                .database
                .from("user_food_preferences")
                .select("food_preferences(id, name, created_at)")
                .eq("user_preference_id", value: userPreferenceId)
                .execute()
                .value
            
            let preferences = results.map { $0.food_preferences }
            print("✅ Kullanıcının \(preferences.count) yemek tercihi başarıyla alındı")
            return preferences
            
        } catch let postgrestError as PostgrestError {
            print("🚫 getUserFoodPreferences - Postgrest Hatası: \(postgrestError)")
            throw SupabaseError.clientError("Seçili yemek tercihleri alınırken hata: \(postgrestError.message ?? "Bilinmeyen hata")")
        } catch {
            print("🚫 getUserFoodPreferences - Bilinmeyen Hata: \(error)")
            throw SupabaseError.clientError("Seçili yemek tercihleri alınırken hata: \(error.localizedDescription)")
        }
    }
    
    func getUserHobbies(userPreferenceId: UUID) async throws -> [HobbyNew] {
        print("🎮 Seçili hobiler alınıyor: \(userPreferenceId)")
        do {
            struct ResultType: Decodable {
                let hobbies: HobbyNew
            }
            
            let results: [ResultType] = try await client
                .database
                .from("user_hobbies")
                .select("hobbies(id, name, created_at)")
                .eq("user_preference_id", value: userPreferenceId)
                .execute()
                .value
            
            let hobbies = results.map { $0.hobbies }
            print("✅ Kullanıcının \(hobbies.count) hobisi başarıyla alındı")
            return hobbies
            
        } catch let postgrestError as PostgrestError {
            print("🚫 getUserHobbies - Postgrest Hatası: \(postgrestError)")
            throw SupabaseError.clientError("Seçili hobiler alınırken hata: \(postgrestError.message ?? "Bilinmeyen hata")")
        } catch {
            print("🚫 getUserHobbies - Bilinmeyen Hata: \(error)")
            throw SupabaseError.clientError("Seçili hobiler alınırken hata: \(error.localizedDescription)")
        }
    }
    
} // PreferenceService sınıfının sonu
