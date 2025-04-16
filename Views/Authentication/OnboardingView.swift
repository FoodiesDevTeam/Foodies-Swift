import SwiftUI

struct OnboardingView: View {
    // Başlangıç ekranı olarak doğrudan PersonalInfo'yu ayarlıyoruz
    @State private var currentStep: OnboardingState = .personalInfo
    @State private var navigateToMainApp = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Sadece ihtiyaç duyulan durumları içeren basitleştirilmiş bir switch yapısı
                switch currentStep {
                case .personalInfo:
                    PersonalInfoView(isEditMode: false, onSave: {
                        print("PersonalInfoView tamamlandı, HobbiesFoodView'a geçiliyor")
                        // Doğrudan HobbiesFoodView'a geçiş
                        withAnimation {
                            currentStep = .hobbiesFood
                        }
                    })
                
                case .hobbiesFood:
                    HobbiesFoodView(onboardingState: .hobbiesFood, onSave: {
                        print("HobbiesFoodView tamamlandı, MatchingPreferencesView'a geçiliyor")
                        withAnimation {
                            currentStep = .matchingPreferences
                        }
                    })
                
                case .matchingPreferences:
                    MatchingPreferencesView(onboardingState: .matchingPreferences) {
                        print("MatchingPreferencesView tamamlandı, PhotosAndBioView'a geçiliyor")
                        withAnimation {
                            currentStep = .photoBio
                        }
                    }
                
                case .photoBio:
                    PhotosAndBioView(onboardingState: .photoBio) {
                        print("PhotosAndBioView tamamlandı, ana uygulamaya geçiliyor")
                        navigateToMainApp = true
                    }
                
                // Kullanılmayan durumlar için otomatik yönlendirme
                default:
                    EmptyView()
                        .onAppear {
                            print("Beklenmeyen durum: \(currentStep), PersonalInfo'ya yönlendiriliyor")
                            withAnimation {
                                currentStep = .personalInfo
                            }
                        }
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                print("OnboardingView görüntülendi, mevcut adım: \(currentStep)")
            }
        }
        .fullScreenCover(isPresented: $navigateToMainApp) {
            MainTabView()
        }
    }
}

#Preview {
    OnboardingView()
}