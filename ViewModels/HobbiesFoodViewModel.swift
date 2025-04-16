import Foundation
import SwiftUI

class HobbiesFoodViewModel: ObservableObject {
    @Published var foodPreferences: [FoodPreferenceNew] = []
    @Published var hobbies: [HobbyNew] = []
    @Published var selectedFoodPreferences: Set<UUID> = []
    @Published var selectedHobbies: Set<UUID> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    
    @MainActor
    func loadPreferences() async {
        // Prevent multiple loads if already loading or data exists
        guard !isLoading && foodPreferences.isEmpty && hobbies.isEmpty else {
            print("🔄 loadPreferences skipped: Already loading or data exists.")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔍 Tercihler yükleniyor...")
            
            // Load available preferences - use Task groups to handle potential partial failures
            async let foodPrefsTask = Task {
                do {
                    print("📍 getFoodPreferences başladı")
                    return try await supabaseService.getFoodPreferences()
                } catch {
                    print("⚠️ Yemek tercihleri yüklenirken hata: \(error)")
                    return [FoodPreferenceNew]() // Return empty array on error
                }
            }
            
            async let hobbiesTask = Task {
                do {
                    print("📍 getHobbies başladı")
                    return try await supabaseService.getHobbies()
                } catch {
                    print("⚠️ Hobiler yüklenirken hata: \(error)")
                    return [HobbyNew]() // Return empty array on error
                }
            }
            
            // Await both tasks to complete
            let (foodPrefs, hobbiesList) = await (foodPrefsTask.value, hobbiesTask.value)
            
            self.foodPreferences = foodPrefs
            self.hobbies = hobbiesList
            
            if foodPrefs.isEmpty && hobbiesList.isEmpty {
                errorMessage = "Tercihler yüklenemedi. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin."
                print("❌ Hiçbir tercih yüklenemedi")
            } else {
                if foodPrefs.isEmpty {
                    print("⚠️ Yemek tercihleri yüklenemedi")
                } else {
                    print("✅ Başarıyla \(self.foodPreferences.count) yemek tercihi yüklendi")
                    print("🍔 Yemek tercihleri: \(self.foodPreferences.map { $0.name })")
                }
                
                if hobbiesList.isEmpty {
                    print("⚠️ Hobiler yüklenemedi")
                } else {
                    print("✅ Başarıyla \(self.hobbies.count) hobi yüklendi")
                    print("🎯 Hobiler: \(self.hobbies.map { $0.name })")
                }
            }
            
            // Load user's existing preferences if any
            if let currentUser = try? await supabaseService.getCurrentUser() {
                do {
                    let userPrefs = try await supabaseService.getUserPreferences(userId: currentUser.id)
                    let userFoodPrefs = try await supabaseService.getUserFoodPreferences(userPreferenceId: userPrefs.id)
                    let userHobbies = try await supabaseService.getUserHobbies(userPreferenceId: userPrefs.id)
                    
                    selectedFoodPreferences = Set(userFoodPrefs.map { $0.id })
                    selectedHobbies = Set(userHobbies.map { $0.id })
                } catch {
                    print("No existing preferences found for user")
                }
            }
            
        } catch {
            print("Error loading preferences: \(error)")
            errorMessage = "Tercihler yüklenirken bir hata oluştu: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func toggleFoodPreference(_ id: UUID) {
        if selectedFoodPreferences.contains(id) {
            selectedFoodPreferences.remove(id)
        } else {
            selectedFoodPreferences.insert(id)
        }
    }
    
    func toggleHobby(_ id: UUID) {
        if selectedHobbies.contains(id) {
            selectedHobbies.remove(id)
        } else {
            selectedHobbies.insert(id)
        }
    }
    
    @MainActor
    func savePreferences() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            print("\u{1F4BE} savePreferences başladı")
            
            guard let currentUser = try await supabaseService.getCurrentUser() else {
                let error = NSError(domain: "PreferencesError",
                             code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın."])
                print("\u{1F6AB} Kullanıcı oturumu bulunamadı")
                errorMessage = error.localizedDescription
                throw error
            }
            
            print("\u{1F464} Mevcut kullanıcı: \(currentUser.id)")
            print("\u{1F4DD} Seçilen hobiler: \(selectedHobbies)")
            print("\u{1F4DD} Seçilen yemek tercihleri: \(selectedFoodPreferences)")
            
            // Seçilen hobi ve yemek isimlerini logla
            let selectedHobbyNames = hobbies.filter { selectedHobbies.contains($0.id) }.map { $0.name }
            let selectedFoodNames = foodPreferences.filter { selectedFoodPreferences.contains($0.id) }.map { $0.name }
            print("\u{1F374} Seçilen yemekler: \(selectedFoodNames)")
            print("\u{1F3AE} Seçilen hobiler: \(selectedHobbyNames)")
            
            try await supabaseService.saveUserPreferences(
                userId: currentUser.id,
                foodPreferences: Array(selectedFoodPreferences),
                hobbies: Array(selectedHobbies)
            )
            
            print("\u{1F389} Tercihler başarıyla kaydedildi!")
        } catch let supabaseError as SupabaseError {
            print("\u{1F6A8} Tercihler kaydedilirken hata: \(supabaseError)")
            errorMessage = "Tercihler kaydedilirken bir hata oluştu: \(supabaseError.localizedDescription)"
            throw supabaseError
        } catch {
            print("\u{1F6A8} Tercihler kaydedilirken hata: \(error)")
            errorMessage = "Tercihler kaydedilirken bir hata oluştu: \(error.localizedDescription)"
            throw error
        }
    }
} 