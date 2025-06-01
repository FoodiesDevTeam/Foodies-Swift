import SwiftUI
import PhotosUI

struct WaveShape: Shape {
    var offset: Angle
    var percent: Double
    
    var animatableData: Double {
        get { offset.degrees }
        set { offset = Angle(degrees: newValue) }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waveHeight = rect.height * 0.1
        let yOffset = rect.height * (1 - percent)

        path.move(to: CGPoint(x: 0, y: yOffset))
        
        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * .pi * 2 + offset.radians)
            let y = yOffset + waveHeight * CGFloat(sine)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

struct ProfileView: View {
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showPhotosAndBio = false
    @State private var navigateToSignIn = false
    @State private var viewRefreshTrigger = false
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showEditBioView = false
    @State private var pulsate = false
    @State private var waveOffset = Angle(degrees: 0)
    @State private var isHovering = false
    let userToDisplay: UserDefaultsManager.User?
    let isCurrentUser: Bool
    
    init(userToDisplay: UserDefaultsManager.User? = nil, isCurrentUser: Bool = true) {
        self.userToDisplay = userToDisplay
        self.isCurrentUser = isCurrentUser
    }
    
    private var userFullName: String {
        guard let info = viewModel.user?.personalInfo else { return "" }
        return "\(info.name) \(info.surname)"
    }
    
    private var userAge: String {
        guard let info = viewModel.user?.personalInfo else { return "" }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: info.birthDate, to: Date())
        guard let age = ageComponents.year else { return "" }
        let formatString = NSLocalizedString("profile_years_old_format", comment: "Age format string")
        return String(format: formatString, age)
    }
    
    private var userLocation: String {
        guard let info = viewModel.user?.personalInfo,
              let city = info.city else { return "" }
        let formatString = NSLocalizedString("profile_location_format", comment: "Location format string")
        return String(format: formatString, city)
    }
    
    // MARK: - View Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.8),
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    ZStack {
                        // Header background
                        LinearGradient(
                            colors: [.pink, .purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 100)
                        .edgesIgnoringSafeArea(.top)

                        // Header Content
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                
                                Text("Profil")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.white)
                                    .font(.system(size: 25))
                                
                                Spacer()
                                
                                if isCurrentUser {
                                    Button {
                                        showSettings = true
                                    } label: {
                                        Image(systemName: "gearshape.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 23))
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, -50)
                        }
                    }

                    ScrollView {
                        VStack(spacing: 20) {
                            // Profile Header
                            profileHeaderView
                                .padding(.top, 15)
                            
                            // Profile Info
                            profileInfoView
                            
                            // Edit Buttons
                            editButtonsView
                                .padding(.bottom, 20)
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onLogout: handleLogout)
        }
        .sheet(isPresented: $showEditProfile) {
            if let currentUser = viewModel.user {
                NavigationView {
                    PersonalInfoView(
                        isEditMode: true,
                        existingInfo: currentUser.personalInfo,
                        onSave: {
                            viewModel.loadUserData()
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showPhotosAndBio) {
            NavigationView {
                PhotosAndBioView(onboardingState: .photoBio)
            }
        }
        .sheet(isPresented: $showEditBioView) {
            EditBioView(
                currentBio: viewModel.user?.bio ?? "",
                onSave: { newBio in
                    viewModel.updateBio(newBio)
                }
            )
        }
        .onChange(of: LanguageManager.shared.currentLanguage) { _ in
            viewRefreshTrigger.toggle()
        }
        .onAppear {
            loadUserData()
        }
        .fullScreenCover(isPresented: $navigateToSignIn) {
            SignInView()
        }
    }
    
    // MARK: - Subviews
    private var profileHeaderView: some View {
        VStack {
            PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                if let photoData = viewModel.user?.photos?.first,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                        .overlay(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 30))
                                )
                                .opacity(isHovering ? 0.7 : 0)
                        )
                        .onHover { hovering in
                            isHovering = hovering
                        }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                        .overlay(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 30))
                                )
                                .opacity(isHovering ? 0.7 : 0)
                        )
                        .onHover { hovering in
                            isHovering = hovering
                        }
                }
            }
            
            if let user = viewModel.user, let info = user.personalInfo {
                Text("\(info.firstName) \(info.lastName)")
                    .font(.title2)
                    .bold()
                
                Text(user.bio ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    private var profileInfoView: some View {
        VStack(spacing: 15) {
            if let user = viewModel.user, let info = user.personalInfo {
                // Basic Info
                infoRow(icon: "person.fill", text: "\(info.firstName) \(info.lastName)")
                infoRow(icon: "calendar", text: viewModel.formatDate(info.birthDate))
                if let city = info.city {
                    infoRow(icon: "mappin.circle.fill", text: city)
                }
                if let occupation = info.occupation {
                    infoRow(icon: "briefcase.fill", text: occupation)
                }
                
                // Status Info
                HStack(spacing: 20) {
                    statusItem(icon: "flame.fill", text: info.smokingStatus == .yes ? "Evet" : "Hayır", title: "Sigara")
                    statusItem(icon: "wineglass.fill", text: info.drinkingStatus == .yes ? "Evet" : "Hayır", title: "Alkol")
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var editButtonsView: some View {
        VStack(spacing: 12) {
            Button(action: { showEditProfile = true }) {
                Label(LanguageManager.shared.localizedString("edit_profile"), systemImage: "pencil")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Button(action: { showEditBioView = true }) {
                Label(LanguageManager.shared.localizedString("edit_bio"), systemImage: "text.quote")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
    
    private func infoRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
            Spacer()
        }
    }
    
    private func statusItem(icon: String, text: String, title: String) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(text)
            }
            .font(.subheadline)
        }
    }
    
    // MARK: - Helper Methods
    private func handleLogout() {
        Task {
            do {
                try await SupabaseService.shared.signOut()
                NotificationCenter.default.post(name: Constants.NotificationNames.userDidLogout, object: nil)
                showSettings = false
                navigateToSignIn = true
            } catch {
                print("Çıkış yapılırken hata oluştu: \(error)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        return viewModel.formatDate(date)
    }
    
    // MARK: - Preferences Views
    private var preferencesView: some View {
        VStack(spacing: 0) {
          
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
    
    private func loadUserData() {
        if isCurrentUser {
            viewModel.loadUserData()
        } else if let user = userToDisplay {
            viewModel.configureFor(user: user)
        }
    }
}

#Preview {
    ProfileView()
}
