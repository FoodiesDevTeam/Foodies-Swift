import SwiftUI
import PhotosUI
import RealmSwift

class CreateProfileViewModel: ObservableObject {
    @Published var currentStep = 1
    
    // Personal Info
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var birthDate = Date()
    @Published var gender = ""
    @Published var city = ""
    @Published var occupation = ""
    @Published var smokes = false
    @Published var drinksAlcohol = false
    
    // Interests
    @Published var selectedCuisines: Set<String> = []
    @Published var selectedHobbies: Set<String> = []
    
    // Matching Preferences
    @Published var smokingPreference = false
    @Published var drinkingPreference = false
    @Published var appPurpose = ""
    @Published var preferredGender = ""
    
    // Photos and Bio
    @Published var photos: [UIImage] = []
    @Published var selectedItem: PhotosPickerItem? {
        didSet {
            Task {
                if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        if photos.count < 3 {
                            photos.append(image)
                        }
                        selectedItem = nil
                    }
                }
            }
        }
    }
    @Published var bio = ""
    
    // Available options
    let availableCuisines = [
        "Türk Mutfağı", "İtalyan", "Uzak Doğu",
        "Meksika", "Hint", "Akdeniz", "Fast Food",
        "Vejeteryan", "Deniz Ürünleri"
    ]
    
    let availableHobbies = [
        "Yemek Yapmak", "Spor", "Seyahat",
        "Müzik", "Sinema", "Kitap Okumak",
        "Fotoğrafçılık", "Dans", "Yoga"
    ]
    
    func nextStep() {
        if currentStep < 4 {
            withAnimation {
                currentStep += 1
            }
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            withAnimation {
                currentStep -= 1
            }
        }
    }
    
    func bindingForCuisine(_ cuisine: String) -> Binding<Bool> {
        Binding(
            get: { self.selectedCuisines.contains(cuisine) },
            set: { isSelected in
                if isSelected {
                    self.selectedCuisines.insert(cuisine)
                } else {
                    self.selectedCuisines.remove(cuisine)
                }
            }
        )
    }
    
    func bindingForHobby(_ hobby: String) -> Binding<Bool> {
        Binding(
            get: { self.selectedHobbies.contains(hobby) },
            set: { isSelected in
                if isSelected {
                    self.selectedHobbies.insert(hobby)
                } else {
                    self.selectedHobbies.remove(hobby)
                }
            }
        )
    }
    
    func removePhoto(at index: Int) {
        photos.remove(at: index)
    }
    
    func completeProfile() {
        let realm = try! Realm()
        
        let profile = UserProfile()
        profile.firstName = firstName
        profile.lastName = lastName
        profile.birthDate = birthDate
        profile.gender = gender
        profile.city = city
        profile.occupation = occupation
        profile.smokes = smokes
        profile.drinksAlcohol = drinksAlcohol
        
        // Add food preferences
        selectedCuisines.forEach { cuisine in
            profile.foodPreferences.append(cuisine)
        }
        
        // Add hobbies
        selectedHobbies.forEach { hobby in
            profile.hobbies.append(hobby)
        }
        
        profile.smokingPreference = smokingPreference
        profile.drinkingPreference = drinkingPreference
        profile.appPurpose = appPurpose
        profile.preferredGender = preferredGender
        profile.bio = bio
        
        // TODO: Upload photos to server and get URLs
        // For now, store dummy URLs
        photos.forEach { _ in
            profile.photoUrls.append("temp_url")
        }
        
        try! realm.write {
            realm.add(profile)
        }
        
        // TODO: Sync with PostgreSQL database
    }
}
