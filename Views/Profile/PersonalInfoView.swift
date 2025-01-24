import SwiftUI

struct PersonalInfoView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthDate = Date()
    @State private var showDatePicker = false
    @State private var gender: UserDefaultsManager.Gender = .any
    @State private var city: String = ""
    @State private var occupation: String = ""
    @State private var smokingStatus: UserDefaultsManager.SmokingStatus = .no
    @State private var drinkingStatus: UserDefaultsManager.DrinkingStatus = .no
    @State private var navigateNext = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Kişisel Bilgiler")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            ScrollView {
                VStack(spacing: 20) {
                    // Ad Soyad
                    Group {
                        CustomTextField(text: $firstName, icon: "person", placeholder: "Adınız")
                        CustomTextField(text: $lastName, icon: "person", placeholder: "Soyadınız")
                    }
                    
                    // Doğum Tarihi
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Doğum Tarihi")
                            .foregroundColor(.gray)
                        Button(action: {
                            showDatePicker = true
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                Text(dateFormatter.string(from: birthDate))
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        }
                    }
                    .sheet(isPresented: $showDatePicker) {
                        DatePickerSheet(birthDate: $birthDate, isPresented: $showDatePicker)
                    }
                    
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
                    
                    // Şehir ve Meslek
                    Group {
                        CustomTextField(text: $city, icon: "location", placeholder: "Şehir")
                        CustomTextField(text: $occupation, icon: "briefcase", placeholder: "Meslek")
                    }
                    
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
                }
                .padding(.horizontal)
            }
            
            // İleri Butonu
            Button(action: {
                savePersonalInfo()
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
            .disabled(firstName.isEmpty || lastName.isEmpty || city.isEmpty || occupation.isEmpty)
        }
        .padding(.top, 50)
        .navigationBarHidden(true)
        .background(
            NavigationLink(isActive: $navigateNext) {
                AppPreferencesView()
            } label: {
                EmptyView()
            }
        )
    }
    
    private func savePersonalInfo() {
        if let username = UserDefaultsManager.shared.getCurrentUser()?.username {
            let personalInfo = UserDefaultsManager.PersonalInfo(
                firstName: firstName,
                lastName: lastName,
                birthDate: birthDate,
                gender: gender,
                city: city.isEmpty ? nil : city,
                occupation: occupation.isEmpty ? nil : occupation,
                smokingStatus: smokingStatus,
                drinkingStatus: drinkingStatus, country: "k"
            )
            UserDefaultsManager.shared.updateUserPersonalInfo(username: username, personalInfo: personalInfo)
            navigateNext = true
        }
    }
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
            }
            Divider()
        }
    }
}

struct DatePickerSheet: View {
    @Binding var birthDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Doğum Tarihi",
                    selection: $birthDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Seç")
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
                .padding()
            }
            .navigationTitle("Doğum Tarihi Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
