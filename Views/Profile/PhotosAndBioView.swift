import SwiftUI
import PhotosUI

struct PhotosAndBioView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var bio: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let onboardingState: OnboardingState
    var onSave: (() -> Void)?
    
    var body: some View {
        VStack(spacing: Constants.Design.defaultSpacing) {
            // Progress Bar
            ProgressView(value: onboardingState.progress)
                .progressViewStyle(.linear)
                .tint(Color.purple)
                .padding(.horizontal)
            
            Text(onboardingState.title)
                .font(.system(size: Constants.FontSizes.title1, weight: .bold))
                .foregroundStyle(Constants.Design.mainGradient)
            
            ScrollView {
                VStack(spacing: Constants.Design.defaultSpacing) {
                    // Fotoğraf Seçici
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 6,
                        matching: .images
                    ) {
                        VStack {
                            if selectedImages.isEmpty {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Fotoğraf Ekle")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            
                            // Seçilen fotoğrafları göster
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 10) {
                                ForEach(selectedImages, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: selectedImages.isEmpty ? 150 : nil)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .onChange(of: selectedItems) { _ in
                        Task {
                            await loadImages()
                        }
                    }
                    
                    // Bio Text Editor
                    VStack(alignment: .leading) {
                        Text("Hakkında")
                            .font(.headline)
                            .foregroundStyle(Constants.Design.mainGradient)
                        
                        TextEditor(text: $bio)
                            .frame(height: 150)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)
            }
            
            // Kaydet ve Bitir Butonu
            Button(action: savePhotosAndBio) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Kaydet ve Bitir")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
                    .fill(Constants.Design.mainGradient)
            )
            .padding(.horizontal)
            .disabled(isLoading || selectedImages.isEmpty)
        }
        .padding(.vertical, Constants.Design.defaultPadding)
        .background(
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
        )
        .navigationBarBackButtonHidden(true)
        .alert("Hata", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadImages() async {
        isLoading = true
        selectedImages.removeAll()
        
        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImages.append(image)
                }
            }
        }
        
        isLoading = false
    }
    
    private func savePhotosAndBio() {
        guard let username = UserDefaultsManager.shared.getCurrentUser()?.username else {
            alertMessage = "Kullanıcı bilgisi bulunamadı"
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Fotoğrafları Data formatına çevir
        let photosData = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.7) }
        
        // UserDefaults'a kaydet
        UserDefaultsManager.shared.updateUserPhotosAndBio(
            username: username,
            photos: photosData,
            bio: bio
        )
        
        isLoading = false
        onSave?()
    }
}

#Preview {
    PhotosAndBioView(onboardingState: .photoBio) { }
}
