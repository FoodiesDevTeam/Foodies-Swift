import SwiftUI

struct OnboardingView: View {
    @State private var currentStep: OnboardingState = .personalInfo
    @State private var navigateToMainApp = false
    
    var body: some View {
        NavigationStack {
            VStack {
                switch currentStep {
                case .personalInfo:
                    PersonalInfoView(isEditMode: false, onSave: {
                        print("PersonalInfoView onSave çağrıldı")
                        withAnimation {
                            currentStep = .matchingPreferences
                            print("currentStep güncellendi: \(currentStep)")
                        }
                    })
                case .matchingPreferences:
                    MatchingPreferencesView(onboardingState: .matchingPreferences) {
                        print("MatchingPreferencesView onSave çağrıldı")
                        withAnimation {
                            currentStep = .hobbiesFood
                            print("currentStep güncellendi: \(currentStep)")
                        }
                    }
                case .hobbiesFood:
                    HobbiesFoodView(onboardingState: .hobbiesFood, onSave: {
                        print("HobbiesFoodView onSave çağrıldı")
                        withAnimation {
                            currentStep = .photoBio
                            print("currentStep güncellendi: \(currentStep)")
                        }
                    })
                case .photoBio:
                    PhotosAndBioView(onboardingState: currentStep) {
                        print("PhotosAndBioView onSave çağrıldı")
                        navigateToMainApp = true
                    }
                case .preferences:
                    EmptyView()
                }
            }
            .navigationBarBackButtonHidden(true)
            .onChange(of: currentStep) { newStep in
                print("currentStep değişti: \(newStep)")
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