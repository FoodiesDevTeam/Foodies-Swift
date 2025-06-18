import Foundation
import SwiftUI
import PhotosUI

class ProfileViewModel: ObservableObject {
    @Published var user: UserDefaultsManager.User?
    @Published var profileImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userFoodPreferences: [FoodPreferenceNew] = []
    @Published var userHobbies: [HobbyNew] = []
    @Published var matchingPreferences: UserDefaultsManager.MatchingPreferences?
    @Published var personalInfo: UserDefaultsManager.PersonalInfo?
    @Published var selectedPhoto: PhotosPickerItem? {
        didSet {
            handlePhotoSelection()
        }
    }
    
    private let supabaseService = SupabaseService.shared
    
    func loadUserData() {
        if let username = UserDefaultsManager.shared.getCurrentUser()?.username {
            let fetchedUser = UserDefaultsManager.shared.getUser(username: username)
            self.user = fetchedUser
            loadProfileImageFromUser()
            personalInfo = user?.personalInfo
            matchingPreferences = user?.matchingPreferences
            Task {
                await loadUserPreferences()
            }
        } else {
            user = nil
            profileImage = nil
            personalInfo = nil
            matchingPreferences = nil
            userFoodPreferences = []
            userHobbies = []
        }
    }
    
    func configureFor(user: UserDefaultsManager.User) {
        DispatchQueue.main.async {
            self.user = user
            self.loadProfileImageFromUser()
            self.personalInfo = user.personalInfo
            self.matchingPreferences = user.matchingPreferences
            // Hobiler ve yemek zevkleri de doldurulsun
            if let appPrefs = user.appPreferences {
                self.userFoodPreferences = appPrefs.foodPreferences.map { FoodPreferenceNew(id: UUID(), name: $0, createdAt: nil) }
                self.userHobbies = appPrefs.hobbies.map { HobbyNew(id: UUID(), name: $0, createdAt: nil) }
            } else {
                self.userFoodPreferences = []
                self.userHobbies = []
            }
        }
    }
    
    private func loadProfileImageFromUser() {
        if let photos = user?.photos, let photoData = photos.first {
            if let image = UIImage(data: photoData) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            } else {
                DispatchQueue.main.async {
                    self.profileImage = nil
                }
            }
        } else {
            DispatchQueue.main.async {
                self.profileImage = nil
            }
        }
    }
    
    @MainActor
    func loadUserPreferences() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let currentUser = try await supabaseService.getCurrentUser() else {
                isLoading = false
                return
            }
            
            do {
                let userPrefs = try await supabaseService.getUserPreferences(userId: currentUser.id)
                
                let userFoodPrefs = try await supabaseService.getUserFoodPreferences(userPreferenceId: userPrefs.id)
                let allFoodPrefs = try await supabaseService.getFoodPreferences()
                let userFoodPrefIds = Set(userFoodPrefs.map { $0.id })
                self.userFoodPreferences = allFoodPrefs.filter { userFoodPrefIds.contains($0.id) }
                
                let userHobbies = try await supabaseService.getUserHobbies(userPreferenceId: userPrefs.id)
                let allHobbies = try await supabaseService.getHobbies()
                let userHobbyIds = Set(userHobbies.map { $0.id })
                self.userHobbies = allHobbies.filter { userHobbyIds.contains($0.id) }
                
            } catch {
                errorMessage = "Tercihler yüklenirken bir hata oluştu: \(error.localizedDescription)"
            }
            
        } catch {
            errorMessage = "Kullanıcı bilgileri yüklenirken bir hata oluştu: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func updateProfilePhoto(_ photoData: Data) {
        guard let username = user?.username else { return }
        
        // Mevcut biyografi verisini al
        let currentBio = user?.bio ?? ""
        
        // Fotoğraf verisini sıkıştır
        let compressedData = compressImageData(photoData)
        
        // Önce UserDefaults'u güncelle
        UserDefaultsManager.shared.updateUserPhotosAndBio(
            username: username,
            photos: [compressedData],
            bio: currentBio
        )
        
        // UserDefaults güncellemesi tamamlandıktan sonra ViewModel'ı güncelle
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if var updatedUser = self.user {
                updatedUser.photos = [compressedData]
                self.user = updatedUser
                
                if let image = UIImage(data: compressedData) {
                    self.profileImage = image
                } else {
                    self.profileImage = nil
                }
            }
        }
    }
    
    private func compressImageData(_ data: Data) -> Data {
        guard let image = UIImage(data: data) else { return data }
        
        // Maksimum boyut (örneğin 1MB)
        let maxSize: Int = 1 * 1024 * 1024
        
        // Eğer veri zaten yeterince küçükse, sıkıştırma yapma
        if data.count <= maxSize {
            return data
        }
        
        // Sıkıştırma kalitesini ayarla (0.0 - 1.0 arası)
        var compression: CGFloat = 0.8
        var compressedData = image.jpegData(compressionQuality: compression)
        
        // Veri boyutu kabul edilebilir seviyeye gelene kadar sıkıştırma kalitesini düşür
        while let data = compressedData, data.count > maxSize && compression > 0.1 {
            compression -= 0.1
            compressedData = image.jpegData(compressionQuality: compression)
        }
        
        return compressedData ?? data
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = LanguageManager.shared.currentLanguage.locale
        return formatter.string(from: date)
    }
    
    func updateBio(_ newBio: String) {
        guard let username = user?.username else { return }
        UserDefaultsManager.shared.updateUserBio(username: username, bio: newBio)
        loadUserData()
    }
    
    private func handlePhotoSelection() {
        Task {
            do {
                if let data = try await selectedPhoto?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        updateProfilePhoto(data)
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Fotoğraf yüklenemedi veya geçersiz."
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Fotoğraf yüklenirken bir hata oluştu: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                self.selectedPhoto = nil
            }
        }
    }
}
