import Foundation
import Supabase
import Auth

enum SupabaseError: Error {
    case invalidURL
    case invalidConfiguration
    case clientError(String)
    case signUpFailed
    case signInFailed
    case signOutFailed
    case sessionError
    case userNotFound
    case dataError
}

// MARK: - User Model
struct AppUser: Codable {
    let id: String
    let email: String
    var username: String
    var avatarURL: String?
    var bio: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(from supabaseUser: Auth.User) {
        self.id = supabaseUser.id.uuidString
        self.email = supabaseUser.email ?? ""
        self.username = supabaseUser.email?.components(separatedBy: "@").first ?? ""
        self.avatarURL = nil
        self.bio = nil
        self.createdAt = supabaseUser.createdAt
        self.updatedAt = supabaseUser.updatedAt
    }
}

// MARK: - Models
struct FoodPreference: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case createdAt = "created_at"
    }
}

struct Hobby: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case createdAt = "created_at"
    }
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
}

struct UserFoodPreference: Codable {
    let userPreferenceId: UUID
    let foodPreferenceId: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userPreferenceId = "user_preference_id"
        case foodPreferenceId = "food_preference_id"
        case createdAt = "created_at"
    }
}

struct UserHobby: Codable {
    let userPreferenceId: UUID
    let hobbyId: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userPreferenceId = "user_preference_id"
        case hobbyId = "hobby_id"
        case createdAt = "created_at"
    }
}

class SupabaseService {
    static let shared = SupabaseService()
    private let client: SupabaseClient
    private let supabaseURL = "https://jysrmcnzqyjfsfcdzzuj.supabase.co"
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp5c3JtY256cXlqZnNmY2R6enVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM5ODYzODksImV4cCI6MjA1OTU2MjM4OX0.JsIXlVF7-uxsaanWkQvHETh371HWwI06ykGhvp4ISdM"
    
    private init() {
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }
        
        do {
            self.client = try SupabaseClient(supabaseURL: url, supabaseKey: supabaseKey)
        } catch {
            fatalError("Failed to initialize Supabase client: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String) async throws -> AppUser {
        do {
            print("Attempting to sign up with email: \(email)")
            let authResponse = try await client.auth.signUp(email: email, password: password)
            
            print("Auth response received: \(authResponse)")
            
            guard let authUser = authResponse.user as? Auth.User else {
                print("Failed to cast user to Auth.User")
                throw SupabaseError.signUpFailed
            }
            
            print("Creating AppUser from Auth.User")
            let appUser = AppUser(from: authUser)
            
            print("Creating user profile")
            try await createUserProfile(appUser)
            
            print("Sign up successful")
            return appUser
        } catch let error as PostgrestError {
            print("PostgrestError: \(error.message)")
            if error.message.contains("users_pkey") || error.message.contains("duplicate key value") {
                throw SupabaseError.clientError("Bu e-posta adresi zaten kullanımda. Lütfen farklı bir e-posta adresi deneyin.")
            }
            throw SupabaseError.clientError(error.message)
        } catch {
            print("Unexpected error during sign up: \(error)")
            let errorMessage = (error as NSError).localizedDescription
            if errorMessage.contains("email rate limit exceeded") {
                throw SupabaseError.clientError("Çok fazla deneme yapıldı. Lütfen birkaç dakika bekleyip tekrar deneyin.")
            }
            throw SupabaseError.clientError("Kayıt işlemi sırasında bir hata oluştu: \(errorMessage)")
        }
    }
    
    func signIn(email: String, password: String) async throws -> AppUser {
        let authResponse = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        guard let authUser = authResponse.user as? Auth.User else {
            throw SupabaseError.signInFailed
        }
        
        return AppUser(from: authUser)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
    
    // MARK: - Session Management
    
    func getCurrentSession() async throws -> Session? {
        try await client.auth.session
    }
    
    func refreshSession() async throws {
        _ = try await client.auth.refreshSession()
    }
    
    // MARK: - User Management
    
    func getCurrentUser() async throws -> AppUser? {
        guard let session = try await getCurrentSession() else {
            return nil
        }
        
        guard let authUser = session.user as? Auth.User else {
            return nil
        }
        
        return AppUser(from: authUser)
    }
    
    func fetchUser(id: String) async throws -> AppUser {
        let user: AppUser = try await client
            .database
            .from("users")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        return user
    }
    
    // MARK: - User Profile Management
    
    func createUserProfile(_ user: AppUser) async throws {
        print("Starting createUserProfile for user: \(user.id)")
        
        struct UserInput: Encodable {
            let id: String
            let email: String
            let username: String
            let avatar_url: String?
            let bio: String?
            let created_at: String
            let updated_at: String
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let userInput = UserInput(
            id: user.id,
            email: user.email,
            username: user.username,
            avatar_url: user.avatarURL,
            bio: user.bio,
            created_at: dateFormatter.string(from: user.createdAt),
            updated_at: dateFormatter.string(from: user.updatedAt)
        )
        
        print("Attempting to insert user profile into database")
        do {
            try await client
                .database
                .from("users")
                .insert(userInput)
                .execute()
            print("User profile created successfully")
        } catch {
            print("Error creating user profile: \(error)")
            throw error
        }
    }
    
    func updateUserProfile(_ user: AppUser) async throws {
        try await client
            .database
            .from("users")
            .update(user)
            .eq("id", value: user.id)
            .execute()
    }
    
    // MARK: - Recipes
    
    func fetchRecipes() async throws -> [Recipe] {
        let recipes: [Recipe] = try await client
            .database
            .from("recipes")
            .select()
            .execute()
            .value
        return recipes
    }
    
    func fetchRecipe(id: String) async throws -> Recipe {
        let recipe: Recipe = try await client
            .database
            .from("recipes")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        return recipe
    }
    
    func createRecipe(_ recipe: Recipe) async throws -> Recipe {
        let newRecipe: Recipe = try await client
            .database
            .from("recipes")
            .insert(recipe)
            .execute()
            .value
        return newRecipe
    }
    
    func updateRecipe(_ recipe: Recipe) async throws -> Recipe {
        let updatedRecipe: Recipe = try await client
            .database
            .from("recipes")
            .update(recipe)
            .eq("id", value: recipe.id)
            .execute()
            .value
        return updatedRecipe
    }
    
    func deleteRecipe(id: String) async throws {
        try await client
            .database
            .from("recipes")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Preferences Management
    
    func getFoodPreferences() async throws -> [FoodPreference] {
        do {
            print("📍 getFoodPreferences başladı")
            let query = client
                .database
                .from("food_preferences")
                .select()
            
            print("🔄 Sorgu çalıştırılıyor...")
            let response = try await query.execute()
            print("✅ Sorgu yanıtı alındı")
            
            guard let responseData = response.data else {
                print("❌ Response data nil")
                throw SupabaseError.dataError
            }
            
            print("📦 Response data tipi:", type(of: responseData))
            
            if let data = responseData as? Data {
                print("🔄 Data tipinden decode ediliyor...")
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let preferences = try decoder.decode([FoodPreference].self, from: data)
                print("✅ Başarıyla \(preferences.count) yemek tercihi yüklendi")
                return preferences
            } else if let array = responseData as? [[String: Any]] {
                print("🔄 Dictionary array'den decode ediliyor...")
                let jsonData = try JSONSerialization.data(withJSONObject: array)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let preferences = try decoder.decode([FoodPreference].self, from: jsonData)
                print("✅ Başarıyla \(preferences.count) yemek tercihi yüklendi")
                return preferences
            } else {
                print("❌ Beklenmeyen response data tipi:", type(of: responseData))
                throw SupabaseError.dataError
            }
        } catch let error as PostgrestError {
            print("❌ PostgrestError:", error.message)
            throw SupabaseError.clientError(error.message)
        } catch {
            print("❌ Beklenmeyen hata:", error)
            print("❌ Hata tipi:", type(of: error))
            print("❌ Hata açıklaması:", error.localizedDescription)
            throw SupabaseError.clientError("Yemek tercihleri yüklenirken bir hata oluştu: \(error.localizedDescription)")
        }
    }
    
    func getHobbies() async throws -> [Hobby] {
        do {
            print("📍 getHobbies başladı")
            let query = client
                .database
                .from("hobbies")
                .select()
            
            print("🔄 Sorgu çalıştırılıyor...")
            let response = try await query.execute()
            print("✅ Sorgu yanıtı alındı")
            
            guard let responseData = response.data else {
                print("❌ Response data nil")
                throw SupabaseError.dataError
            }
            
            print("📦 Response data tipi:", type(of: responseData))
            
            if let data = responseData as? Data {
                print("🔄 Data tipinden decode ediliyor...")
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let hobbies = try decoder.decode([Hobby].self, from: data)
                print("✅ Başarıyla \(hobbies.count) hobi yüklendi")
                return hobbies
            } else if let array = responseData as? [[String: Any]] {
                print("🔄 Dictionary array'den decode ediliyor...")
                let jsonData = try JSONSerialization.data(withJSONObject: array)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let hobbies = try decoder.decode([Hobby].self, from: jsonData)
                print("✅ Başarıyla \(hobbies.count) hobi yüklendi")
                return hobbies
            } else {
                print("❌ Beklenmeyen response data tipi:", type(of: responseData))
                throw SupabaseError.dataError
            }
        } catch let error as PostgrestError {
            print("❌ PostgrestError:", error.message)
            throw SupabaseError.clientError(error.message)
        } catch {
            print("❌ Beklenmeyen hata:", error)
            print("❌ Hata tipi:", type(of: error))
            print("❌ Hata açıklaması:", error.localizedDescription)
            throw SupabaseError.clientError("Hobiler yüklenirken bir hata oluştu: \(error.localizedDescription)")
        }
    }
    
    func getUserPreferences(userId: String) async throws -> UserPreferences {
        do {
            let query = client
                .database
                .from("user_preferences")
                .select()
                .eq("user_id", value: userId)
                .single()
            
            let response = try await query.execute()
            
            guard let responseData = response.data as? [String: Any] else {
                throw SupabaseError.dataError
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: responseData)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let preferences = try decoder.decode(UserPreferences.self, from: jsonData)
            return preferences
        } catch {
            throw SupabaseError.clientError("Kullanıcı tercihleri yüklenirken bir hata oluştu")
        }
    }
    
    func getUserFoodPreferences(userPreferenceId: UUID) async throws -> [FoodPreference] {
        do {
            let query = client
                .database
                .from("user_food_preferences")
                .select("""
                    food_preference_id,
                    food_preferences (
                        id,
                        name,
                        category,
                        created_at
                    )
                """)
                .eq("user_preference_id", value: userPreferenceId.uuidString)
            
            let response = try await query.execute()
            
            guard let responseData = response.data as? [[String: Any]] else {
                throw SupabaseError.dataError
            }
            
            let preferences = responseData.compactMap { data -> FoodPreference? in
                guard let foodPrefData = data["food_preferences"] as? [String: Any] else { return nil }
                
                guard let jsonData = try? JSONSerialization.data(withJSONObject: foodPrefData) else { return nil }
                return try? JSONDecoder().decode(FoodPreference.self, from: jsonData)
            }
            
            return preferences
        } catch {
            throw SupabaseError.clientError("Kullanıcının yemek tercihleri yüklenirken bir hata oluştu")
        }
    }
    
    func getUserHobbies(userPreferenceId: UUID) async throws -> [Hobby] {
        do {
            let query = client
                .database
                .from("user_hobbies")
                .select("""
                    hobby_id,
                    hobbies (
                        id,
                        name,
                        category,
                        created_at
                    )
                """)
                .eq("user_preference_id", value: userPreferenceId.uuidString)
            
            let response = try await query.execute()
            
            guard let responseData = response.data as? [[String: Any]] else {
                throw SupabaseError.dataError
            }
            
            let hobbies = responseData.compactMap { data -> Hobby? in
                guard let hobbyData = data["hobbies"] as? [String: Any] else { return nil }
                
                guard let jsonData = try? JSONSerialization.data(withJSONObject: hobbyData) else { return nil }
                return try? JSONDecoder().decode(Hobby.self, from: jsonData)
            }
            
            return hobbies
        } catch {
            throw SupabaseError.clientError("Kullanıcının hobileri yüklenirken bir hata oluştu")
        }
    }
    
    func saveUserPreferences(userId: String, foodPreferences: [UUID], hobbies: [UUID]) async throws {
        do {
            // 1. Create or get user preferences
            let userPreferences: UserPreferences
            do {
                userPreferences = try await getUserPreferences(userId: userId)
            } catch {
                // Create new user preferences if not exists
                let query = try client
                    .database
                    .from("user_preferences")
                    .insert(["user_id": userId])
                    .single()
                
                let response = try await query.execute()
                guard let responseData = response.data as? [String: Any] else {
                    throw SupabaseError.dataError
                }
                
                let jsonData = try JSONSerialization.data(withJSONObject: responseData)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                userPreferences = try decoder.decode(UserPreferences.self, from: jsonData)
            }
            
            // 2. Delete existing preferences
            try await client
                .database
                .from("user_food_preferences")
                .delete()
                .eq("user_preference_id", value: userPreferences.id.uuidString)
                .execute()
            
            try await client
                .database
                .from("user_hobbies")
                .delete()
                .eq("user_preference_id", value: userPreferences.id.uuidString)
                .execute()
            
            // 3. Insert new food preferences
            if !foodPreferences.isEmpty {
                let foodPrefsData = foodPreferences.map { [
                    "user_preference_id": userPreferences.id.uuidString,
                    "food_preference_id": $0.uuidString
                ] }
                
                try await client
                    .database
                    .from("user_food_preferences")
                    .insert(foodPrefsData)
                    .execute()
            }
            
            // 4. Insert new hobbies
            if !hobbies.isEmpty {
                let hobbiesData = hobbies.map { [
                    "user_preference_id": userPreferences.id.uuidString,
                    "hobby_id": $0.uuidString
                ] }
                
                try await client
                    .database
                    .from("user_hobbies")
                    .insert(hobbiesData)
                    .execute()
            }
            
        } catch {
            throw SupabaseError.clientError("Kullanıcı tercihleri kaydedilirken bir hata oluştu")
        }
    }
} 
