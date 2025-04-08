import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var bio = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // Arkaplan gradyanı
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
            
            VStack(spacing: Constants.Design.defaultSpacing) {
                Text("Profili Düzenle")
                    .font(.system(size: Constants.FontSizes.title1, weight: .bold))
                    .foregroundStyle(Constants.Design.mainGradient)
                
                ScrollView {
                    VStack(spacing: Constants.Design.defaultSpacing) {
                        // Profil Fotoğrafı
                        VStack(spacing: Constants.Design.defaultPadding) {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Constants.Design.mainGradient, lineWidth: 2)
                                    )
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                            .foregroundColor(.gray)
                                    )
                            }
                            
                            PhotosPicker(selection: $selectedItem,
                                       matching: .images) {
                                Text("Fotoğraf Seç")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, Constants.Design.defaultPadding)
                                    .padding(.vertical, 8)
                                    .background(Constants.Design.mainGradient)
                                    .cornerRadius(Constants.Design.cornerRadius)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        
                        // Bio
                        VStack(alignment: .leading, spacing: Constants.Design.defaultPadding) {
                            Text("Bio")
                                .font(.headline)
                                .foregroundStyle(Constants.Design.mainGradient)
                            
                            TextEditor(text: $bio)
                                .frame(height: 150)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(Constants.Design.cornerRadius)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Kaydet Butonu
                Button(action: saveProfile) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Kaydet")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Constants.Design.mainGradient)
                .cornerRadius(Constants.Design.cornerRadius)
                .padding(.horizontal)
                .disabled(isLoading)
            }
            .padding(.top, Constants.Design.defaultPadding)
        }
        .onChange(of: selectedItem) { _ in
            Task {
                if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    profileImage = image
                }
            }
        }
        .alert("Hata", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadCurrentProfile()
        }
        .navigationBarHidden(true)
    }
    
    private func loadCurrentProfile() {
        if let user = UserDefaultsManager.shared.getCurrentUser() {
            bio = user.bio ?? ""
            if let photoData = user.photos?.first,
               let image = UIImage(data: photoData) {
                profileImage = image
            }
        }
    }
    
    private func saveProfile() {
        guard !bio.isEmpty else {
            alertMessage = "Lütfen kendinizi tanıtan bir bio yazın"
            showAlert = true
            return
        }
        
        isLoading = true
        
        if let username = UserDefaultsManager.shared.getCurrentUser()?.username {
            // Profil fotoğrafını Data'ya çevir
            let photoData = profileImage?.jpegData(compressionQuality: 0.7)
            
            UserDefaultsManager.shared.updateUserPhotosAndBio(
                username: username,
                photos: photoData.map { [$0] } ?? [],
                bio: bio
            )
            dismiss()
        }
        
        isLoading = false
    }
}
