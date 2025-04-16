import SwiftUI

struct HobbiesFoodView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = HobbiesFoodViewModel()
    @State private var navigateToMatchingPreferences = false
    let onboardingState: OnboardingState
    var onSave: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            ProgressView(value: onboardingState.progress)
                .progressViewStyle(.linear)
                .tint(Color.purple)
                .frame(maxWidth: .infinity)
                .frame(height: 4)
                .padding(.horizontal)
                .padding(.bottom, 12)
            
            // Title
            Text(onboardingState.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Constants.Design.mainGradient)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            
            if viewModel.isLoading && viewModel.foodPreferences.isEmpty && viewModel.hobbies.isEmpty {
                // Loading View
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
            } else {
                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        // FOOD PREFERENCES SECTION
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Yemek Tercihleriniz")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.gray)
                                    
                                    Text("Seçili: \(viewModel.selectedFoodPreferences.count)/\(viewModel.foodPreferences.count)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            
                            // Food Preferences List
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(viewModel.foodPreferences) { preference in
                                    Button(action: {
                                        viewModel.toggleFoodPreference(preference.id)
                                    }) {
                                        HStack {
                                            Text(preference.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule()
                                                .fill(viewModel.selectedFoodPreferences.contains(preference.id) ? 
                                                      AnyShapeStyle(Constants.Design.mainGradient) : 
                                                      AnyShapeStyle(Color(.systemGray6)))
                                        )
                                        .foregroundColor(viewModel.selectedFoodPreferences.contains(preference.id) ? .white : .primary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                        )
                        
                        // HOBBIES SECTION
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Hobileriniz")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.gray)
                                    
                                    Text("Seçili: \(viewModel.selectedHobbies.count)/\(viewModel.hobbies.count)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            
                            // Hobbies List
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(viewModel.hobbies) { hobby in
                                    Button(action: {
                                        viewModel.toggleHobby(hobby.id)
                                    }) {
                                        HStack {
                                            Text(hobby.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule()
                                                .fill(viewModel.selectedHobbies.contains(hobby.id) ? 
                                                      AnyShapeStyle(Constants.Design.mainGradient) : 
                                                      AnyShapeStyle(Color(.systemGray6)))
                                        )
                                        .foregroundColor(viewModel.selectedHobbies.contains(hobby.id) ? .white : .primary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            
            // Next Button
            Button(action: completeRegistration) {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("İleri")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Constants.Design.mainGradient)
                    .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .opacity(viewModel.selectedHobbies.isEmpty || viewModel.selectedFoodPreferences.isEmpty ? 0.6 : 1.0)
            .disabled(viewModel.isLoading || viewModel.selectedHobbies.isEmpty || viewModel.selectedFoodPreferences.isEmpty)
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
        .padding(.top, 16)
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
    
    private func completeRegistration() {
        Task {
            do {
                // Hobiler ve yemek tercihleri seçildiğini kontrol et
                if viewModel.selectedHobbies.isEmpty || viewModel.selectedFoodPreferences.isEmpty {
                    await MainActor.run {
                        viewModel.errorMessage = "Lütfen en az bir hobi ve bir yemek tercihi seçin."
                    }
                    return
                }
                
                if viewModel.selectedHobbies.count > 5 {
                    await MainActor.run {
                        viewModel.errorMessage = "En fazla 5 hobi seçebilirsiniz."
                    }
                    return
                }
                
                if viewModel.selectedFoodPreferences.count > 5 {
                    await MainActor.run {
                        viewModel.errorMessage = "En fazla 5 yemek tercihi seçebilirsiniz."
                    }
                    return
                }
                
                print("📝 Seçilen hobiler: \(viewModel.selectedHobbies)")
                print("📝 Seçilen yemek tercihleri: \(viewModel.selectedFoodPreferences)")
                
                // Seçilen hobi ve yemek isimlerini logla
                let selectedHobbyNames = viewModel.hobbies
                    .filter { viewModel.selectedHobbies.contains($0.id) }
                    .map { $0.name }
                let selectedFoodNames = viewModel.foodPreferences
                    .filter { viewModel.selectedFoodPreferences.contains($0.id) }
                    .map { $0.name }
                
                print("🍴 Seçilen yemekler: \(selectedFoodNames)")
                print("🎮 Seçilen hobiler: \(selectedHobbyNames)")
                
                try await viewModel.savePreferences()
                
                // Başarılı kayıttan sonra bir sonraki ekrana geç
                await MainActor.run {
                    print("✅ Tercihler başarıyla kaydedildi, Eşleşme Tercihleri ekranına geçiliyor")
                    if let onSave = onSave {
                        onSave()
                    } else {
                        navigateToMatchingPreferences = true
                    }
                }
            } catch {
                // Hata detaylarını yazdır
                print("🔴 Tercihler kaydedilirken hata: \(error)")
                
                // Supabase hatası için özel işlem
                if let supabaseError = error as? SupabaseError {
                    await MainActor.run {
                        switch supabaseError {
                        case .clientError(let message):
                            viewModel.errorMessage = "Veritabanı hatası: \(message)"
                        case .dataError:
                            viewModel.errorMessage = "Veri formatı hatası: Veriler doğru formatta değil."
                        case .userAlreadyExists:
                            viewModel.errorMessage = "Bu e-posta adresi zaten kayıtlı. Lütfen giriş yapın veya başka bir e-posta adresi kullanın."
                        case .invalidURL, .invalidConfiguration, .signUpFailed, .signInFailed, .signOutFailed, .resetPasswordFailed, .sessionError, .userNotFound:
                            viewModel.errorMessage = "Sistem hatası: \(supabaseError.localizedDescription)"
                        }
                    }
                } else {
                    await MainActor.run {
                        viewModel.errorMessage = "Tercihler kaydedilirken bir hata oluştu: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

#Preview {
    HobbiesFoodView(onboardingState: .hobbiesFood)
}
