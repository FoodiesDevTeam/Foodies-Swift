import SwiftUI

struct HobbiesFoodView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = HobbiesFoodViewModel()
    @State private var navigateToMatchingPreferences = false
    let onboardingState: OnboardingState
    var onSave: (() -> Void)?
    
    var body: some View {
        VStack(spacing: Constants.Design.defaultSpacing) {
            progressBar
            titleView
            ScrollView {
                VStack(spacing: Constants.Design.defaultSpacing) {
                    if viewModel.isLoading && viewModel.foodPreferences.isEmpty && viewModel.hobbies.isEmpty {
                        loadingView
                    } else {
                        hobbiesSection
                        foodPreferencesSection
                    }
                }
                .padding(.horizontal)
            }
            nextButton
        }
        .padding(.top, Constants.Design.defaultPadding)
        .background(backgroundGradient)
        .navigationBarBackButtonHidden(true)
        .alert("Hata", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Tamam", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .fullScreenCover(isPresented: $navigateToMatchingPreferences) {
            MatchingPreferencesView(onboardingState: .matchingPreferences)
        }
        .task {
            await viewModel.loadPreferences()
        }
    }
    
    private var progressBar: some View {
        ProgressView(value: onboardingState.progress)
            .progressViewStyle(.linear)
            .tint(Color.purple)
            .padding(.horizontal)
    }
    
    private var titleView: some View {
        Text(onboardingState.title)
            .font(.system(size: Constants.FontSizes.title1, weight: .bold))
            .foregroundStyle(Constants.Design.mainGradient)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
                .padding()
            Text("Tercihler yükleniyor...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 50)
    }
    
    private var hobbiesSection: some View {
        VStack(alignment: .leading, spacing: Constants.Design.defaultPadding) {
            Text("Hobileriniz")
                .font(.headline)
                .foregroundColor(.gray)
            
            hobbiesFlowLayout
        }
        .padding()
        .background(sectionBackground)
    }
    
    private var hobbiesFlowLayout: some View {
        let hobbies = viewModel.hobbies.map { $0.name }
        let selectedHobbiesNames = Set(viewModel.hobbies.filter { viewModel.selectedHobbies.contains($0.id) }.map { $0.name })
        
        return FlowLayout(
            items: hobbies,
            isSelected: { selectedHobbiesNames.contains($0) },
            onTap: { hobbyName in
                if let hobby = viewModel.hobbies.first(where: { $0.name == hobbyName }) {
                    viewModel.toggleHobby(hobby.id)
                }
            },
            spacing: 8
        ) { hobbyName in
            preferenceChip(
                text: hobbyName,
                isSelected: selectedHobbiesNames.contains(hobbyName)
            )
        }
    }
    
    private var foodPreferencesSection: some View {
        VStack(alignment: .leading, spacing: Constants.Design.defaultPadding) {
            Text("Yemek Tercihleriniz")
                .font(.headline)
                .foregroundColor(.gray)
            
            foodPreferencesFlowLayout
        }
        .padding()
        .background(sectionBackground)
    }
    
    private var foodPreferencesFlowLayout: some View {
        let preferences = viewModel.foodPreferences.map { $0.name }
        let selectedPreferencesNames = Set(viewModel.foodPreferences.filter { viewModel.selectedFoodPreferences.contains($0.id) }.map { $0.name })
        
        return FlowLayout(
            items: preferences,
            isSelected: { selectedPreferencesNames.contains($0) },
            onTap: { preferenceName in
                if let preference = viewModel.foodPreferences.first(where: { $0.name == preferenceName }) {
                    viewModel.toggleFoodPreference(preference.id)
                }
            },
            spacing: 8
        ) { preferenceName in
            preferenceChip(
                text: preferenceName,
                isSelected: selectedPreferencesNames.contains(preferenceName)
            )
        }
    }
    
    private func preferenceChip(text: String, isSelected: Bool) -> some View {
        Text(text)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? AnyShapeStyle(Constants.Design.mainGradient) : AnyShapeStyle(Color.gray.opacity(0.1)))
            )
            .foregroundColor(isSelected ? .white : .primary)
    }
    
    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
            .fill(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var nextButton: some View {
        Button(action: completeRegistration) {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("İleri")
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
        .disabled(viewModel.isLoading || viewModel.selectedHobbies.isEmpty || viewModel.selectedFoodPreferences.isEmpty)
    }
    
    private var backgroundGradient: some View {
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
    }
    
    private func completeRegistration() {
        Task {
            do {
                try await viewModel.savePreferences()
                navigateToMatchingPreferences = true
            } catch {
                // Hata zaten ViewModel'de işleniyor
            }
        }
    }
} 