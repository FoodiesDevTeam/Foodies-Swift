import SwiftUI

struct PersonalInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = PersonalInfoViewModel()
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthDate = Date()
    @State private var showDatePicker = false
    @State private var gender: UserDefaultsManager.Gender = .male
    @State private var city: String = ""
    @State private var occupation: String = ""
    @State private var smokingStatus: UserDefaultsManager.SmokingStatus = .no
    @State private var drinkingStatus: UserDefaultsManager.DrinkingStatus = .no
    @State private var isLoading = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var onboardingState: OnboardingState = .personalInfo
    @State private var navigateToPreferences = false
    
    let isEditMode: Bool
    var onSave: (() -> Void)?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
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
                    // Ad Soyad
                    Group {
                        CustomTextField(text: $firstName, icon: "person", placeholder: "Adınız")
                        CustomTextField(text: $lastName, icon: "person", placeholder: "Soyadınız")
                    }
                    .padding(.horizontal)
                    
                    // Doğum Tarihi
                    VStack(alignment: .leading, spacing: Constants.Design.defaultPadding) {
                        Text("Doğum Tarihi")
                            .foregroundColor(.gray)
                        Button(action: {
                            showDatePicker = true
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                Text(dateFormatter.string(from: birthDate))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(Constants.Design.cornerRadius)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Cinsiyet
                    VStack(alignment: .leading) {
                        Text("Cinsiyet")
                            .foregroundColor(.gray)
                        Picker("Cinsiyet", selection: $gender) {
                            Text("Erkek").tag(UserDefaultsManager.Gender.male)
                            Text("Kadın").tag(UserDefaultsManager.Gender.female)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)
                    
                    // Şehir ve Meslek
                    Group {
                        CustomTextField(text: $city, icon: "location", placeholder: "Şehir")
                        CustomTextField(text: $occupation, icon: "briefcase", placeholder: "Meslek")
                    }
                    .padding(.horizontal)
                    
                    // Sigara ve Alkol Kullanımı
                    Group {
                        VStack(alignment: .leading) {
                            Text("Sigara kullanıyor musunuz?")
                                .foregroundColor(.gray)
                            Picker("Sigara", selection: $smokingStatus) {
                                Text("Evet").tag(UserDefaultsManager.SmokingStatus.yes)
                                Text("Hayır").tag(UserDefaultsManager.SmokingStatus.no)
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Alkol kullanıyor musunuz?")
                                .foregroundColor(.gray)
                            Picker("Alkol", selection: $drinkingStatus) {
                                Text("Evet").tag(UserDefaultsManager.DrinkingStatus.yes)
                                Text("Hayır").tag(UserDefaultsManager.DrinkingStatus.no)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            
            // İleri/Kaydet Butonu
            Button(action: {
                savePersonalInfo()
            }) {
                Text("İleri")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Constants.Design.mainGradient)
                    .cornerRadius(Constants.Design.cornerRadius)
            }
            .disabled(isLoading)
            .padding()
            
            NavigationLink(destination: AppPreferencesView(onboardingState: .preferences), isActive: $navigateToPreferences) {
                EmptyView()
            }
        }
        .padding(.top, Constants.Design.defaultPadding)
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
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(birthDate: $birthDate, isPresented: $showDatePicker)
        }
        .alert("Hata", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func savePersonalInfo() {
        print("savePersonalInfo başladı")
        guard validateFields() else { 
            print("validateFields başarısız")
            return 
        }
        
        isLoading = true
        print("Yükleniyor başladı")
        
        let personalInfo = UserDefaultsManager.PersonalInfo(
            name: firstName,
            surname: lastName,
            birthDate: birthDate,
            phoneNumber: "",
            countryCode: "",
            smokingStatus: smokingStatus,
            drinkingStatus: drinkingStatus,
            city: city,
            occupation: occupation,
            email: "",
            gender: gender
        )
        
        if let username = UserDefaultsManager.shared.getCurrentUser()?.username {
            print("Kullanıcı bulundu: \(username)")
            UserDefaultsManager.shared.updateUserPersonalInfo(username: username, personalInfo: personalInfo)
            print("Kullanıcı bilgileri güncellendi")
            
            if isEditMode {
                print("Edit mode: true")
                onSave?()
                isLoading = false
                dismiss()
            } else {
                print("Edit mode: false, onSave çağrılıyor")
                onSave?()
                isLoading = false
                navigateToPreferences = true
            }
        } else {
            print("Kullanıcı bulunamadı")
            // Kullanıcı henüz kaydedilmemişse, yeni kullanıcı oluştur
            let newUsername = UUID().uuidString
            let newUser = UserDefaultsManager.User(username: newUsername)
            UserDefaultsManager.shared.setCurrentUser(username: newUsername)
            UserDefaultsManager.shared.updateUserPersonalInfo(username: newUsername, personalInfo: personalInfo)
            print("Yeni kullanıcı oluşturuldu ve bilgiler kaydedildi")
            onSave?()
            isLoading = false
            if !isEditMode {
                navigateToPreferences = true
            }
        }
    }
    
    private func validateFields() -> Bool {
        if firstName.isEmpty {
            alertMessage = "Lütfen adınızı girin"
            showAlert = true
            return false
        }
        
        if lastName.isEmpty {
            alertMessage = "Lütfen soyadınızı girin"
            showAlert = true
            return false
        }
        
        if city.isEmpty {
            alertMessage = "Lütfen şehir bilgisini girin"
            showAlert = true
            return false
        }
        
        if occupation.isEmpty {
            alertMessage = "Lütfen meslek bilgisini girin"
            showAlert = true
            return false
        }
        
        return true
    }
}

class PersonalInfoViewModel: ObservableObject {
    @Published var isNavigatingToPreferences = false
}

struct CustomTextField: View {
    @Binding var text: String
    let icon: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.vertical, 8)
            Divider()
                .background(Color.gray.opacity(0.5))
        }
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

struct DatePickerSheet: View {
    @Binding var birthDate: Date
    @Binding var isPresented: Bool
    
    private let gradient = LinearGradient(
        colors: [.blue, .purple, .pink],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arkaplan gradyanı
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
                
                VStack {
                    DatePicker(
                        "Doğum Tarihi",
                        selection: $birthDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Seç")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(gradient)
                            .cornerRadius(12)
                            .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .padding()
                }
            }
            .navigationTitle("Doğum Tarihi Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        isPresented = false
                    }
                    .foregroundStyle(gradient)
                }
            }
        }
    }
}
