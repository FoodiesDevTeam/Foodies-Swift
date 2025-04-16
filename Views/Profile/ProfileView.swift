import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showPhotosAndBio = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var navigateToSignIn = false
    @State private var viewRefreshTrigger = false
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Computed Properties
    private var userFullName: String {
        guard let info = viewModel.user?.personalInfo else { return "" }
        return "\(info.name) \(info.surname)"
    }
    
    private var userAge: String {
        guard let info = viewModel.user?.personalInfo else { return "" }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: info.birthDate, to: Date())
        guard let age = ageComponents.year else { return "" }
        return String(format: "%d yaş", age)
    }
    
    private var userLocation: String {
        guard let info = viewModel.user?.personalInfo,
              let city = info.city else { return "" }
        return "\(city), TR"
    }
    
    // MARK: - View Body
    var body: some View {
        VStack(spacing: 0) {
            headerView
            ScrollView {
                VStack(spacing: 20) {
                    profileInfoView
                    infoListView
                    
                    // Yemek Tercihleri ve Hobiler
                    if !viewModel.userFoodPreferences.isEmpty || !viewModel.userHobbies.isEmpty {
                        preferencesView
                    }
                    
                    // Eşleşme Tercihleri
                    if let matchingPrefs = viewModel.matchingPreferences {
                        matchingPreferencesView(matchingPrefs)
                    }
                }
                .padding(.top, 20)
            }
            .background(Color(UIColor.systemGray6))
        }
        .id(viewRefreshTrigger)
        .edgesIgnoringSafeArea(.top)
        .sheet(isPresented: $showSettings) {
            SettingsView(onLogout: handleLogout)
        }
        .sheet(isPresented: $showEditProfile) {
            NavigationView {
                PersonalInfoView(isEditMode: true, onSave: handleProfileUpdate)
            }
        }
        .sheet(isPresented: $showPhotosAndBio) {
            NavigationView {
                PhotosAndBioView(onboardingState: .photoBio)
            }
        }
        .fullScreenCover(isPresented: $navigateToSignIn) {
            SignInView()
        }
        .onChange(of: selectedItem) { newValue in
            handlePhotoSelection(newValue)
        }
        .onChange(of: LanguageManager.shared.currentLanguage) { _ in
            viewRefreshTrigger.toggle()
        }
        .onAppear {
            viewModel.loadUserData()
        }
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        ZStack {
            LinearGradient(
                colors: [.pink, .purple, .blue],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 100)
            
            HStack {
                Spacer()
                Text(LanguageManager.shared.localizedString("profile"))
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                Spacer()
                
                Button(action: { showSettings = true }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                }
            }
            .padding(.horizontal)
            .padding(.top, 40)
        }
    }
    
    private var profileInfoView: some View {
        VStack(spacing: 10) {
            profilePhotoView
            profileBasicInfoView
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 1)
        .padding(.horizontal)
    }
    
    private var profilePhotoView: some View {
        VStack {
            Group {
                if let profileImage = viewModel.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .padding(.top, 20)
                } else if let photos = viewModel.user?.photos,
                          let photoData = photos.first,
                          let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .padding(.top, 20)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .padding(.top, 20)
                }
            }
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Text("Fotoğraf Seç")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            Button(action: { showPhotosAndBio = true }) {
                Text("Bio Düzenle")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding(.top, 5)
        }
    }
    
    private var profileBasicInfoView: some View {
        VStack(spacing: 5) {
            Text(userFullName)
                .font(.title2)
                .bold()
            
            if let occupation = viewModel.user?.personalInfo?.occupation {
                Text(occupation)
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            Text(userAge)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 2)
            
            Text(userLocation)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if let bio = viewModel.user?.bio {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal)
            }
        }
        .padding(.bottom, 15)
    }
    
    private var infoListView: some View {
        VStack(spacing: 0) {
            infoRow(icon: "person", text: userFullName)
            if let email = viewModel.user?.email {
                infoRow(icon: "envelope", text: email)
            }
            if let birthDate = viewModel.user?.personalInfo?.birthDate {
                infoRow(icon: "calendar", text: formatDate(birthDate))
            }
            if let city = viewModel.user?.personalInfo?.city {
                infoRow(icon: "mappin.and.ellipse", text: city)
            }
            if let occupation = viewModel.user?.personalInfo?.occupation {
                infoRow(icon: "briefcase", text: occupation, isLast: true)
            }
        }
        .cornerRadius(12)
        .shadow(radius: 1)
        .padding(.horizontal)
    }
    
    private func infoRow(icon: String, text: String, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 30)
                Text(text)
                    .foregroundColor(.black)
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            
            if !isLast {
                Divider()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleLogout() {
        if let username = viewModel.user?.username {
            UserDefaultsManager.shared.removeUser(username: username)
            NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
        }
        showSettings = false
    }
    
    private func handleProfileUpdate() {
        showEditProfile = false
        viewModel.loadUserData()
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        Task {
            if let data = try? await item?.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                viewModel.updateProfilePhoto(data)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        return viewModel.formatDate(date)
    }
    
    // MARK: - Preferences Views
    private var preferencesView: some View {
        VStack(spacing: 0) {
            // Yemek Tercihleri
            if !viewModel.userFoodPreferences.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Yemek Zevkleri")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.userFoodPreferences) { food in
                                foodPreferenceTag(food.name)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 10)
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Hobiler
            if !viewModel.userHobbies.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hobiler")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.userHobbies) { hobby in
                                hobbyTag(hobby.name)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 10)
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 10)
            }
        }
    }
    
    private func foodPreferenceTag(_ name: String) -> some View {
        Text(name)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.pink, .purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
    }
    
    private func hobbyTag(_ name: String) -> some View {
        Text(name)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
    }
    
    // Eşleşme Tercihleri Görünümü
    private func matchingPreferencesView(_ preferences: UserDefaultsManager.MatchingPreferences) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Eşleşme Tercihleri")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 10)
            
            VStack(spacing: 10) {
                preferenceRow(title: "Sigara Kullanımı", value: preferenceOptionText(preferences.smokingPreference))
                preferenceRow(title: "Alkol Kullanımı", value: preferenceOptionText(preferences.drinkingPreference))
                preferenceRow(title: "Eşleşme Amacı", value: matchingPurposeText(preferences.purpose))
                preferenceRow(title: "Tercih Edilen Cinsiyet", value: genderText(preferences.preferredGender))
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
        .padding(.horizontal)
    }
    
    private func preferenceRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 5)
    }
    
    private func preferenceOptionText(_ option: UserDefaultsManager.PreferenceOption) -> String {
        switch option {
        case .yes: return "Evet"
        case .no: return "Hayır"
        case .dontCare: return "Farketmez"
        }
    }
    
    private func matchingPurposeText(_ purpose: UserDefaultsManager.MatchingPurpose) -> String {
        switch purpose {
        case .friendship: return "Arkadaşlık"
        case .dating: return "Flört"
        case .business: return "Networking"
        case .diningCompanion: return "Yemek Arkadaşı"
        }
    }
    
    private func genderText(_ gender: UserDefaultsManager.Gender) -> String {
        switch gender {
        case .male: return "Erkek"
        case .female: return "Kadın"
        case .any: return "Farketmez"
        }
    }
}
