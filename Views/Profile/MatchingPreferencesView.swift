import SwiftUI

struct MatchingPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var smokingPreference: UserDefaultsManager.PreferenceOption = .dontCare
    @State private var drinkingPreference: UserDefaultsManager.PreferenceOption = .dontCare
    @State private var purpose: UserDefaultsManager.MatchingPurpose = .friendship
    @State private var preferredGender: UserDefaultsManager.Gender = .any
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToMainApp = false
    
    let onboardingState: OnboardingState
    var onSave: (() -> Void)?
    
    init(onboardingState: OnboardingState, onSave: (() -> Void)? = nil) {
        self.onboardingState = onboardingState
        self.onSave = onSave
    }
    
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
                    // Sigara Tercihi
                    PreferenceSection(
                        title: "Sigara Kullanımı",
                        selection: $smokingPreference,
                        options: [
                            (UserDefaultsManager.PreferenceOption.yes, "Evet"),
                            (UserDefaultsManager.PreferenceOption.no, "Hayır"),
                            (UserDefaultsManager.PreferenceOption.dontCare, "Farketmez")
                        ]
                    )
                    
                    // Alkol Tercihi
                    PreferenceSection(
                        title: "Alkol Kullanımı",
                        selection: $drinkingPreference,
                        options: [
                            (UserDefaultsManager.PreferenceOption.yes, "Evet"),
                            (UserDefaultsManager.PreferenceOption.no, "Hayır"),
                            (UserDefaultsManager.PreferenceOption.dontCare, "Farketmez")
                        ]
                    )
                    
                    // Eşleşme Amacı
                    PreferenceSection(
                        title: "Eşleşme Amacı",
                        selection: $purpose,
                        options: [
                            (UserDefaultsManager.MatchingPurpose.friendship, "Arkadaşlık"),
                            (UserDefaultsManager.MatchingPurpose.dating, "Flört"),
                            (UserDefaultsManager.MatchingPurpose.business, "Networking")
                        ]
                    )
                    
                    // Tercih Edilen Cinsiyet
                    PreferenceSection(
                        title: "Tercih Edilen Cinsiyet",
                        selection: $preferredGender,
                        options: [
                            (UserDefaultsManager.Gender.male, "Erkek"),
                            (UserDefaultsManager.Gender.female, "Kadın"),
                            (UserDefaultsManager.Gender.any, "Farketmez")
                        ]
                    )
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: .infinity)
            
            // Kaydet ve Bitir Butonu
            Button(action: savePreferences) {
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
            .padding(.bottom, Constants.Design.defaultPadding)
            .disabled(isLoading)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
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
        .fullScreenCover(isPresented: $navigateToMainApp) {
            MainTabView()
        }
    }
    
    private func savePreferences() {
        isLoading = true
        
        if let username = UserDefaultsManager.shared.getCurrentUser()?.username {
            let preferences = UserDefaultsManager.MatchingPreferences(
                smokingPreference: smokingPreference,
                drinkingPreference: drinkingPreference,
                purpose: purpose,
                preferredGender: preferredGender
            )
            
            UserDefaultsManager.shared.updateUserMatchingPreferences(username: username, matchingPreferences: preferences)
            onSave?()
        } else {
            alertMessage = "Kullanıcı bilgisi bulunamadı"
            showAlert = true
        }
        
        isLoading = false
    }
}

struct PreferenceSection<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [(T, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Design.defaultPadding) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Constants.Design.mainGradient)
            
            VStack(spacing: 8) {
                ForEach(options, id: \.0) { option in
                    Button(action: { selection = option.0 }) {
                        HStack {
                            Text(option.1)
                                .foregroundColor(.primary)
                            Spacer()
                            if selection == option.0 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
                                .fill(selection == option.0 ? Color.blue.opacity(0.1) : Color(.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
                                .stroke(selection == option.0 ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}
