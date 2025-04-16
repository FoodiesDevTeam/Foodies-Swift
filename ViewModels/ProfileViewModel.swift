import Foundation
import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var user: UserDefaultsManager.User?
    @Published var profileImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userFoodPreferences: [FoodPreferenceNew] = []
    @Published var userHobbies: [HobbyNew] = []
    @Published var matchingPreferences: UserDefaultsManager.MatchingPreferences?
    @Published var personalInfo: UserDefaultsManager.PersonalInfo?
    
    private let supabaseService = SupabaseService.shared
    
    func loadUserData() {
        if let username = UserDefaultsManager.shared.getCurrentUser()?.username {
            user = UserDefaultsManager.shared.getUser(username: username)
            loadProfileImage()
            
            // Kullanıcı bilgilerini al
            personalInfo = user?.personalInfo
            matchingPreferences = user?.matchingPreferences
            
            // Supabase'den kullanıcı tercihlerini yükle
            Task {
                await loadUserPreferences()
            }
        }
    }
    
    private func loadProfileImage() {
        if let photos = user?.photos, !photos.isEmpty {
            if let image = UIImage(data: photos[0]) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }
    }
    
    @MainActor
    func loadUserPreferences() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔍 Kullanıcı tercihleri yükleniyor...")
            
            guard let currentUser = try await supabaseService.getCurrentUser() else {
                print("❌ Mevcut kullanıcı bulunamadı")
                isLoading = false
                return
            }
            
            print("👤 Kullanıcı bulundu: \(currentUser.id)")
            
            // Kullanıcı tercihlerini yükle
            do {
                let userPrefs = try await supabaseService.getUserPreferences(userId: currentUser.id)
                print("✅ Kullanıcı tercihleri bulundu: \(userPrefs.id)")
                
                // Yemek tercihlerini yükle
                let userFoodPrefs = try await supabaseService.getUserFoodPreferences(userPreferenceId: userPrefs.id)
                print("🍔 Kullanıcı yemek tercihleri yüklendi: \(userFoodPrefs.count) adet")
                
                // Tüm yemek tercihlerini yükle
                let allFoodPrefs = try await supabaseService.getFoodPreferences()
                
                // Kullanıcının seçtiği yemek tercihlerini filtrele
                let userFoodPrefIds = Set(userFoodPrefs.map { $0.id })
                self.userFoodPreferences = allFoodPrefs.filter { userFoodPrefIds.contains($0.id) }
                print("🍽️ Kullanıcı yemek tercihleri: \(self.userFoodPreferences.map { $0.name })")
                
                // Hobilerini yükle
                let userHobbies = try await supabaseService.getUserHobbies(userPreferenceId: userPrefs.id)
                print("🎮 Kullanıcı hobileri yüklendi: \(userHobbies.count) adet")
                
                // Tüm hobileri yükle
                let allHobbies = try await supabaseService.getHobbies()
                
                // Kullanıcının seçtiği hobileri filtrele
                let userHobbyIds = Set(userHobbies.map { $0.id })
                self.userHobbies = allHobbies.filter { userHobbyIds.contains($0.id) }
                print("🎯 Kullanıcı hobileri: \(self.userHobbies.map { $0.name })")
                
            } catch {
                print("❌ Kullanıcı tercihleri yüklenirken hata: \(error)")
                errorMessage = "Tercihler yüklenirken bir hata oluştu: \(error.localizedDescription)"
            }
            
        } catch {
            print("❌ Kullanıcı bilgileri yüklenirken hata: \(error)")
            errorMessage = "Kullanıcı bilgileri yüklenirken bir hata oluştu: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateProfilePhoto(_ photoData: Data) {
        guard let username = user?.username else { return }
        var photos = user?.photos ?? []
        if !photos.isEmpty {
            photos[0] = photoData
        } else {
            photos.append(photoData)
        }
        UserDefaultsManager.shared.updateUserPhotos(username: username, photos: photos)
        loadUserData()
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage == .english ? "en_US" : "tr_TR")
        return formatter.string(from: date)
    }
}
