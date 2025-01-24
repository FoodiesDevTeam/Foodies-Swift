import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var user: UserDefaultsManager.User?
    
    private var userFullName: String {
        if let info = user?.personalInfo {
            return "\(info.firstName) \(info.lastName)"
        }
        return ""
    }
    
    private var userAge: String {
        if let info = user?.personalInfo,
           let age = Calendar.current.dateComponents([.year], from: info.birthDate, to: Date()).year {
            return "\(age) Years old"
        }
        return ""
    }
    
    private var userLocation: String {
        if let info = user?.personalInfo,
           let city = info.city {
            return "\(city), \(info.country)"
        }
        return ""
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                LinearGradient(
                    colors: [.pink, .purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                
                HStack {
                    Text("Profile")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                }
                .padding()
            }
            .frame(height: 60)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Photo
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let profileImage = profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .scaledToFill()
                                } else if let photoData = user?.photos?.first,
                                          let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Color.gray.opacity(0.3)
                                }
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Circle()
                                    .fill(Color.purple)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16))
                                    )
                            }
                        }
                        
                        if !userFullName.isEmpty {
                            Text(userFullName)
                                .font(.title2)
                                .bold()
                        }
                        
                        if let occupation = user?.personalInfo?.occupation {
                            Text(occupation)
                                .foregroundColor(.gray)
                        }
                        
                        if !userAge.isEmpty {
                            Text(userAge)
                                .foregroundColor(.gray)
                        }
                        
                        if !userLocation.isEmpty {
                            Text(userLocation)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical)
                    
                    // Profile Info
                    VStack(spacing: 24) {
                        if let info = user?.personalInfo {
                            ProfileInfoRow(icon: "person.fill", title: info.firstName)
                        }
                        
                        if let email = user?.email {
                            ProfileInfoRow(icon: "envelope.fill", title: email)
                        }
                        
                        if let birthDate = user?.personalInfo?.birthDate {
                            ProfileInfoRow(icon: "calendar", title: formatDate(birthDate))
                        }
                        
                        if let city = user?.personalInfo?.city {
                            ProfileInfoRow(icon: "mappin.and.ellipse", title: city)
                        }
                        
                        if let occupation = user?.personalInfo?.occupation {
                            ProfileInfoRow(icon: "briefcase.fill", title: occupation)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                }
            }
            
            // Bottom Navigation
            HStack(spacing: 0) {
                ForEach(["house.fill", "message.fill", "heart.fill", "person.fill"], id: \.self) { icon in
                    Button(action: {}) {
                        VStack(spacing: 4) {
                            Image(systemName: icon)
                                .font(.system(size: 20))
                            Circle()
                                .fill(icon == "person.fill" ? Color.red : Color.clear)
                                .frame(width: 4, height: 4)
                        }
                        .foregroundColor(icon == "person.fill" ? .red : .gray)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color.white)
            .shadow(radius: 2)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(user: user)
        }
        .onChange(of: selectedItem) { newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    profileImage = image
                    updateProfilePhoto(data)
                }
            }
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        user = UserDefaultsManager.shared.getCurrentUser()
    }
    
    private func updateProfilePhoto(_ photoData: Data) {
        guard var currentUser = user else { return }
        if currentUser.photos == nil {
            currentUser.photos = []
        }
        currentUser.photos?.insert(photoData, at: 0)
        UserDefaultsManager.shared.updateCurrentUser(user: currentUser)
        loadUserData()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.black)
            
            Spacer()
        }
    }
}
