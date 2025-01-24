import SwiftUI

struct MatchingPreferencesView: View {
    @State private var smokingPreference: UserDefaultsManager.PreferenceOption = .dontCare
    @State private var drinkingPreference: UserDefaultsManager.PreferenceOption = .dontCare
    @State private var purpose: UserDefaultsManager.MatchingPurpose = .diningCompanion
    @State private var preferredGender: UserDefaultsManager.Gender = .any
    @State private var navigateNext = false
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Eşleşme Tercihleri")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Sigara Tercihi
                    VStack(alignment: .leading) {
                        Text("Karşı tarafın sigara içmesi?")
                            .foregroundColor(.gray)
                        Picker("Sigara Tercihi", selection: $smokingPreference) {
                            Text("Evet").tag(UserDefaultsManager.PreferenceOption.yes)
                            Text("Hayır").tag(UserDefaultsManager.PreferenceOption.no)
                            Text("Önemli Değil").tag(UserDefaultsManager.PreferenceOption.dontCare)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Alkol Tercihi
                    VStack(alignment: .leading) {
                        Text("Karşı tarafın alkol kullanması?")
                            .foregroundColor(.gray)
                        Picker("Alkol Tercihi", selection: $drinkingPreference) {
                            Text("Evet").tag(UserDefaultsManager.PreferenceOption.yes)
                            Text("Hayır").tag(UserDefaultsManager.PreferenceOption.no)
                            Text("Önemli Değil").tag(UserDefaultsManager.PreferenceOption.dontCare)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Uygulama Kullanım Amacı
                    VStack(alignment: .leading) {
                        Text("Uygulama kullanma amacınız")
                            .foregroundColor(.gray)
                        Picker("Amaç", selection: $purpose) {
                            Text("Flört etmek").tag(UserDefaultsManager.MatchingPurpose.dating)
                            Text("Arkadaş edinmek").tag(UserDefaultsManager.MatchingPurpose.friendship)
                            Text("Yemek arkadaşı").tag(UserDefaultsManager.MatchingPurpose.diningCompanion)
                            Text("İş görüşmesi").tag(UserDefaultsManager.MatchingPurpose.business)
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                    }
                    
                    // Tercih Edilen Cinsiyet
                    VStack(alignment: .leading) {
                        Text("Eşleşmek istediğiniz cinsiyet")
                            .foregroundColor(.gray)
                        Picker("Cinsiyet", selection: $preferredGender) {
                            Text("Erkek").tag(UserDefaultsManager.Gender.male)
                            Text("Kadın").tag(UserDefaultsManager.Gender.female)
                            Text("Önemli Değil").tag(UserDefaultsManager.Gender.any)
                        }
                        .pickerStyle(.segmented)
                    }
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
        }
        .padding(.top, 50)
        .navigationBarHidden(true)
        .background(
            NavigationLink(isActive: $navigateNext) {
                PhotosAndBioView()
            } label: {
                EmptyView()
            }
        )
    }
    
    private func savePreferences() {
        if let username = UserDefaultsManager.shared.getCurrentUser()?.username {
            let preferences = UserDefaultsManager.MatchingPreferences(
                smokingPreference: smokingPreference,
                drinkingPreference: drinkingPreference,
                purpose: purpose,
                preferredGender: preferredGender
            )
            UserDefaultsManager.shared.updateUserMatchingPreferences(username: username, matchingPreferences: preferences)
        }
    }
}
