import Foundation
import SwiftUI

class HobbiesFoodViewModel: ObservableObject {
    @Published var foodPreferences: [FoodPreference] = []
    @Published var hobbies: [Hobby] = []
    @Published var selectedFoodPreferences: Set<UUID> = []
    @Published var selectedHobbies: Set<UUID> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    
    @MainActor
    func loadPreferences() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("Loading preferences...")
            
            // Load available preferences
            async let foodPrefsTask = supabaseService.getFoodPreferences()
            async let hobbiesTask = supabaseService.getHobbies()
            
            let (foodPrefs, hobbiesList) = try await (foodPrefsTask, hobbiesTask)
            
            self.foodPreferences = foodPrefs
            self.hobbies = hobbiesList
            
            print("Successfully loaded \(self.foodPreferences.count) food preferences and \(self.hobbies.count) hobbies")
            
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
        guard let currentUser = try? await supabaseService.getCurrentUser() else {
            throw NSError(domain: "UserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bulunamadı"])
        }
        
        try await supabaseService.saveUserPreferences(
            userId: currentUser.id,
            foodPreferences: Array(selectedFoodPreferences),
            hobbies: Array(selectedHobbies)
        )
    }
} 