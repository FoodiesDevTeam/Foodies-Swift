import SwiftUI

struct SecurityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
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
            
            VStack(spacing: Constants.Design.defaultSpacing) {
                Text("Güvenlik")
                    .font(.system(size: Constants.FontSizes.title1, weight: .bold))
                    .foregroundStyle(Constants.Design.mainGradient)
                
                VStack(spacing: Constants.Design.defaultSpacing) {
                    // Mevcut Şifre
                    VStack(alignment: .leading, spacing: Constants.Design.defaultPadding) {
                        Text("Mevcut Şifre")
                            .font(.headline)
                            .foregroundStyle(Constants.Design.mainGradient)
                        
                        SecureField("Mevcut şifrenizi girin", text: $currentPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    
                    // Yeni Şifre
                    VStack(alignment: .leading, spacing: Constants.Design.defaultPadding) {
                        Text("Yeni Şifre")
                            .font(.headline)
                            .foregroundStyle(Constants.Design.mainGradient)
                        
                        SecureField("Yeni şifrenizi girin", text: $newPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                        
                        Text("Şifreniz en az 8 karakter uzunluğunda olmalıdır")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    
                    // Şifre Onayı
                    VStack(alignment: .leading, spacing: Constants.Design.defaultPadding) {
                        Text("Şifre Onayı")
                            .font(.headline)
                            .foregroundStyle(Constants.Design.mainGradient)
                        
                        SecureField("Yeni şifrenizi tekrar girin", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Şifre Değiştir Butonu
                Button(action: changePassword) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Şifre Değiştir")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Constants.Design.mainGradient)
                .cornerRadius(Constants.Design.cornerRadius)
                .padding(.horizontal)
                .disabled(isLoading)
            }
            .padding(.top, Constants.Design.defaultPadding)
        }
        .alert("Hata", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .navigationBarHidden(true)
    }
    
    private func changePassword() {
        guard !currentPassword.isEmpty else {
            alertMessage = "Lütfen mevcut şifrenizi girin"
            showAlert = true
            return
        }
        
        guard !newPassword.isEmpty else {
            alertMessage = "Lütfen yeni şifrenizi girin"
            showAlert = true
            return
        }
        
        guard newPassword.count >= 8 else {
            alertMessage = "Yeni şifreniz en az 8 karakter uzunluğunda olmalıdır"
            showAlert = true
            return
        }
        
        guard newPassword == confirmPassword else {
            alertMessage = "Şifreler eşleşmiyor"
            showAlert = true
            return
        }
        
        isLoading = true
        
        if let username = UserDefaultsManager.shared.getCurrentUser()?.username {
            if UserDefaultsManager.shared.validatePassword(username: username, password: currentPassword) {
                UserDefaultsManager.shared.updatePassword(username: username, newPassword: newPassword)
                dismiss()
            } else {
                alertMessage = "Mevcut şifreniz yanlış"
                showAlert = true
            }
        }
        
        isLoading = false
    }
}

struct TwoFactorSetupView: View {
    @Environment(\.dismiss) var dismiss
    let username: String
    @State private var verificationCode = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("İki Faktörlü Kimlik Doğrulama Kurulumu")) {
                    Text("Güvenliğiniz için telefonunuza bir doğrulama kodu gönderdik.")
                        .padding(.vertical)
                    
                    TextField("Doğrulama Kodu", text: $verificationCode)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button(action: verifyCode) {
                        Text("Doğrula")
                    }
                }
            }
            .navigationTitle("2FA Kurulumu")
            .navigationBarItems(
                leading: Button("İptal") {
                    UserDefaultsManager.shared.toggleTwoFactor(for: username)
                    dismiss()
                }
            )
            .alert("Hata", isPresented: $showAlert) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func verifyCode() {
        guard !verificationCode.isEmpty else {
            alertMessage = "Lütfen doğrulama kodunu girin"
            showAlert = true
            return
        }
        
        // Burada doğrulama kodu kontrolü yapılacak
        // Şimdilik sadece boş olmadığını kontrol ediyoruz
        if verificationCode.count == 6 {
            dismiss()
        } else {
            alertMessage = "Geçersiz doğrulama kodu"
            showAlert = true
        }
    }
}

struct PrivacySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showProfileTo = "Everyone"
    @State private var showLocationTo = "Matches Only"
    @State private var showOnlineStatus = true
    @State private var showReadReceipts = true
    
    var body: some View {
        Form {
            Section(header: Text("Profile Visibility")) {
                Picker("Show Profile To", selection: $showProfileTo) {
                    Text("Everyone").tag("Everyone")
                    Text("Matches Only").tag("Matches Only")
                    Text("Nobody").tag("Nobody")
                }
                
                Picker("Show Location To", selection: $showLocationTo) {
                    Text("Everyone").tag("Everyone")
                    Text("Matches Only").tag("Matches Only")
                    Text("Nobody").tag("Nobody")
                }
            }
            
            Section(header: Text("Activity Status")) {
                Toggle("Show Online Status", isOn: $showOnlineStatus)
                Toggle("Show Read Receipts", isOn: $showReadReceipts)
            }
            
            Section(header: Text("Data")) {
                Button(action: {
                    // Download personal data
                }) {
                    Text("Download My Personal Data")
                }
                
                Button(action: {
                    // Delete all data
                }) {
                    Text("Delete All My Data")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Privacy Settings")
    }
}

struct BlockedUsersView: View {
    @State private var blockedUsers: [String] = []
    
    var body: some View {
        List {
            if blockedUsers.isEmpty {
                Text("No blocked users")
                    .foregroundColor(.gray)
            } else {
                ForEach(blockedUsers, id: \.self) { username in
                    HStack {
                        Text(username)
                        Spacer()
                        Button("Unblock") {
                            unblockUser(username)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle("Blocked Users")
        .onAppear {
            loadBlockedUsers()
        }
    }
    
    private func loadBlockedUsers() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            // Gerçek engellenen kullanıcıları yükle
            blockedUsers = []
        }
    }
    
    private func unblockUser(_ username: String) {
        if let index = blockedUsers.firstIndex(of: username) {
            blockedUsers.remove(at: index)
            // Engeli kaldırma işlemini gerçekleştir
        }
    }
}
