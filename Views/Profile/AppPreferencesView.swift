import SwiftUI

struct AppPreferencesView: View {
    @State private var foodPreferences: Set<String> = []
    @State private var hobbies: Set<String> = []
    @State private var navigateNext = false
    
    let availableFoodPreferences = [
        "Türk Mutfağı", "İtalyan Mutfağı", "Uzak Doğu Mutfağı", "Fast Food",
        "Vejetaryen", "Vegan", "Deniz Ürünleri", "Sokak Lezzetleri",
        "Tatlılar", "Kahve", "Çay"
    ]
    
    let availableHobbies = [
        "Spor", "Müzik", "Sinema", "Kitap Okumak", "Seyahat",
        "Fotoğrafçılık", "Dans", "Yemek Yapmak", "Resim",
        "Doğa Sporları", "Teknoloji", "Oyun"
    ]
    
    var body: some View {
        VStack(spacing: 25) {
            Text("İlgi Alanları")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Yemek Tercihleri")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    FlowLayout(
                        items: availableFoodPreferences,
                        isSelected: { foodPreferences.contains($0) },
                        onTap: { preference in
                            if foodPreferences.contains(preference) {
                                foodPreferences.remove(preference)
                            } else {
                                foodPreferences.insert(preference)
                            }
                        },
                        spacing: 8
                    )
                    .frame(height: 200)
                    
                    Text("Hobiler")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding(.top)
                    
                    FlowLayout(
                        items: availableHobbies,
                        isSelected: { hobbies.contains($0) },
                        onTap: { hobby in
                            if hobbies.contains(hobby) {
                                hobbies.remove(hobby)
                            } else {
                                hobbies.insert(hobby)
                            }
                        },
                        spacing: 8
                    )
                    .frame(height: 200)
                }
                .padding(.horizontal)
            }
            
            // İleri Butonu
            Button(action: {
                savePreferences()
                navigateNext = true
            }) {
                Text("İleri")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(foodPreferences.isEmpty || hobbies.isEmpty)
        }
        .padding(.top, 50)
        .navigationBarHidden(true)
        .background(
            NavigationLink(isActive: $navigateNext) {
                MatchingPreferencesView()
            } label: {
                EmptyView()
            }
        )
    }
    
    private func savePreferences() {
        if let username = UserDefaultsManager.shared.getCurrentUser()?.username {
            let preferences = UserDefaultsManager.AppPreferences(
                foodPreferences: Array(foodPreferences),
                hobbies: Array(hobbies)
            )
            UserDefaultsManager.shared.updateUserAppPreferences(username: username, appPreferences: preferences)
        }
    }
}

struct FlowLayout: View {
    let items: [String]
    let isSelected: (String) -> Bool
    let onTap: (String) -> Void
    let spacing: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                PreferenceChip(
                    title: item,
                    isSelected: isSelected(item),
                    action: { onTap(item) }
                )
                .padding([.horizontal, .vertical], 4)
                .alignmentGuide(.leading) { dimension in
                    if abs(width - dimension.width) > geometry.size.width {
                        width = 0
                        height -= dimension.height
                    }
                    let result = width
                    if item == items.last {
                        width = 0
                    } else {
                        width -= dimension.width
                    }
                    return result
                }
                .alignmentGuide(.top) { _ in
                    let result = height
                    if item == items.last {
                        height = 0
                    }
                    return result
                }
            }
        }
    }
}

struct PreferenceChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.purple : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .black)
        }
    }
}
