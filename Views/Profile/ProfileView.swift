import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showPhotosAndBio = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var user: UserDefaultsManager.User?
    @State private var navigateToSignIn = false
    @State private var viewRefreshTrigger = false
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Computed Properties
    private var userFullName: String {
        guard let info = user?.personalInfo else { return "" }
        return "\(info.name) \(info.surname)"
    }
    
    private var userAge: String {
        guard let info = user?.personalInfo else { return "" }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: info.birthDate, to: Date())
        guard let age = ageComponents.year else { return "" }
        return String(format: "%d yaş", age)
    }
    
    private var userLocation: String {
        guard let info = user?.personalInfo,
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
            loadUserData()
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
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .padding(.top, 20)
                } else if let photos = user?.photos,
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
            
            Button(action: { showPhotosAndBio = true }) {
                Text("Fotoğraf ve Bio Düzenle")
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
            
            if let occupation = user?.personalInfo?.occupation {
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
            
            if let bio = user?.bio {
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
            if let email = user?.email {
                infoRow(icon: "envelope", text: email)
            }
            if let birthDate = user?.personalInfo?.birthDate {
                infoRow(icon: "calendar", text: formatDate(birthDate))
            }
            if let city = user?.personalInfo?.city {
                infoRow(icon: "mappin.and.ellipse", text: city)
            }
            if let occupation = user?.personalInfo?.occupation {
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
        if let username = user?.username {
            UserDefaultsManager.shared.removeUser(username: username)
            NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
        }
        showSettings = false
    }
    
    private func handleProfileUpdate() {
        showEditProfile = false
        loadUserData()
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        Task {
            if let data = try? await item?.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                profileImage = image
                updateProfilePhoto(data)
            }
        }
    }
    
    private func loadUserData() {
        if let username = UserDefaultsManager.shared.getCurrentUser()?.username {
            user = UserDefaultsManager.shared.getUser(username: username)
        }
    }
    
    private func updateProfilePhoto(_ photoData: Data) {
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage == .english ? "en_US" : "tr_TR")
        return formatter.string(from: date)
    }
}
