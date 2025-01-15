import SwiftUI
import PhotosUI

struct CreateProfileView: View {
    @StateObject private var viewModel = CreateProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress Steps
                StepIndicator(currentStep: viewModel.currentStep)
                    .padding(.top)
                
                // Current Step View
                Group {
                    switch viewModel.currentStep {
                    case 1:
                        personalInfoSection
                    case 2:
                        interestsSection
                    case 3:
                        matchingPreferencesSection
                    case 4:
                        photoAndBioSection
                    default:
                        EmptyView()
                    }
                }
                .transition(.slide)
                
                // Navigation Buttons
                navigationButtons
            }
            .padding()
        }
        .background(Color(uiColor: .systemGray6))
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Profil Oluştur")
    }
    
    // MARK: - Personal Info Section
    private var personalInfoSection: some View {
        VStack(spacing: 15) {
            Text("Kişisel Bilgiler")
                .font(.title2)
                .bold()
            
            Group {
                InputField(text: $viewModel.firstName, placeholder: "Ad", icon: "person")
                InputField(text: $viewModel.lastName, placeholder: "Soyad", icon: "person")
                
                DatePicker("Doğum Tarihi", selection: $viewModel.birthDate, displayedComponents: .date)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                
                Picker("Cinsiyet", selection: $viewModel.gender) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Text(gender.rawValue).tag(gender.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                
                InputField(text: $viewModel.city, placeholder: "Şehir", icon: "mappin")
                InputField(text: $viewModel.occupation, placeholder: "Meslek", icon: "briefcase")
                
                Toggle("Sigara kullanıyor musunuz?", isOn: $viewModel.smokes)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                
                Toggle("Alkol kullanıyor musunuz?", isOn: $viewModel.drinksAlcohol)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Interests Section
    private var interestsSection: some View {
        VStack(spacing: 15) {
            Text("İlgi Alanları")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Favori Mutfaklar")
                    .font(.headline)
                
                ForEach(viewModel.availableCuisines, id: \.self) { cuisine in
                    Toggle(cuisine, isOn: viewModel.bindingForCuisine(cuisine))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Hobiler")
                    .font(.headline)
                
                ForEach(viewModel.availableHobbies, id: \.self) { hobby in
                    Toggle(hobby, isOn: viewModel.bindingForHobby(hobby))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Matching Preferences Section
    private var matchingPreferencesSection: some View {
        VStack(spacing: 15) {
            Text("Eşleşme Tercihleri")
                .font(.title2)
                .bold()
            
            Group {
                Toggle("Karşı tarafın sigara içmesini ister misiniz?", isOn: $viewModel.smokingPreference)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                
                Toggle("Karşı tarafın alkol kullanmasını ister misiniz?", isOn: $viewModel.drinkingPreference)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                
                Picker("Uygulama Kullanım Amacı", selection: $viewModel.appPurpose) {
                    ForEach(AppPurpose.allCases, id: \.self) { purpose in
                        Text(purpose.rawValue).tag(purpose.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                
                Picker("Eşleşmek İstediğiniz Cinsiyet", selection: $viewModel.preferredGender) {
                    ForEach(PreferredGender.allCases, id: \.self) { gender in
                        Text(gender.rawValue).tag(gender.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Photo and Bio Section
    private var photoAndBioSection: some View {
        VStack(spacing: 15) {
            Text("Fotoğraf ve Biyografi")
                .font(.title2)
                .bold()
            
            Text("En fazla 3 fotoğraf yükleyebilirsiniz")
                .foregroundColor(.gray)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(0..<3) { index in
                    if index < viewModel.photos.count {
                        Image(uiImage: viewModel.photos[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                Button(action: {
                                    viewModel.removePhoto(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .padding(5)
                                }
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .padding(5),
                                alignment: .topTrailing
                            )
                    } else {
                        PhotosPicker(selection: $viewModel.selectedItem,
                                   matching: .images) {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "plus")
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                }
            }
            .padding(.vertical)
            
            VStack(alignment: .leading) {
                Text("Kendinizi Tanıtın")
                    .font(.headline)
                
                TextEditor(text: $viewModel.bio)
                    .frame(height: 150)
                    .padding(5)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack {
            if viewModel.currentStep > 1 {
                Button(action: { viewModel.previousStep() }) {
                    Text("Geri")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(10)
                }
            }
            
            Button(action: {
                if viewModel.currentStep == 4 {
                    viewModel.completeProfile()
                } else {
                    viewModel.nextStep()
                }
            }) {
                Text(viewModel.currentStep == 4 ? "Tamamla" : "İleri")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
            }
        }
        .padding(.top)
    }
}

// MARK: - Step Indicator
struct StepIndicator: View {
    let currentStep: Int
    let totalSteps = 4
    
    var body: some View {
        HStack {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.blue : Color.gray)
                    .frame(width: 10, height: 10)
                
                if step < totalSteps {
                    Rectangle()
                        .fill(step < currentStep ? Color.blue : Color.gray)
                        .frame(height: 2)
                }
            }
        }
    }
}

// MARK: - Input Field
struct InputField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}
