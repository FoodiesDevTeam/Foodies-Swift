import SwiftUI
import PhotosUI

struct PhotosAndBioView: View {
    @State private var bio = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedPhotosData: [Data] = []
    @State private var showMainView = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Fotoğraflarını ve Bio'nu Ekle")
                .font(.title)
                .bold()
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Photos Picker
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 6,
                matching: .images
            ) {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)
                    Text("Fotoğraf Seç (Max 6)")
                        .foregroundColor(.purple)
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Selected Photos Preview
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(selectedPhotosData, id: \.self) { photoData in
                        if let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    Button(action: {
                                        if let index = selectedPhotosData.firstIndex(of: photoData) {
                                            selectedPhotosData.remove(at: index)
                                            selectedItems.remove(at: index)
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(Circle())
                                    }
                                    .padding(5),
                                    alignment: .topTrailing
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Bio TextField
            VStack(alignment: .leading) {
                Text("Bio")
                    .font(.headline)
                TextEditor(text: $bio)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                Text("\(bio.count)/500 karakter")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            // Save Button
            Button(action: {
                savePhotosAndBio()
            }) {
                Text("Kaydet ve Devam Et")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .onChange(of: selectedItems) { items in
            Task {
                selectedPhotosData = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        selectedPhotosData.append(data)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showMainView) {
            MainTabView()
        }
    }
    
    private func savePhotosAndBio() {
        if let username = UserDefaultsManager.shared.getCurrentUser()?.username {
            UserDefaultsManager.shared.updateUserPhotosAndBio(
                username: username,
                photos: selectedPhotosData,
                bio: bio
            )
            showMainView = true
        }
    }
}

struct PhotosAndBioView_Previews: PreviewProvider {
    static var previews: some View {
        PhotosAndBioView()
    }
}
