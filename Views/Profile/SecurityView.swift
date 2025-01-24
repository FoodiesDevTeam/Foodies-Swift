import SwiftUI

struct SecurityView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showTwoFactorSetup = false
    @State private var showBiometricSetup = false
    @State private var settings: UserDefaultsManager.UserSettings?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Authentication")) {
                    if let settings = settings {
                        NavigationLink(destination: TwoFactorSetupView(isEnabled: settings.twoFactorEnabled)) {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.yellow)
                                Text("Two-Factor Authentication")
                                Spacer()
                                if settings.twoFactorEnabled {
                                    Text("On")
                                        .foregroundColor(.green)
                                } else {
                                    Text("Off")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        Toggle(isOn: .constant(true)) {
                            HStack {
                                Image(systemName: "faceid")
                                    .foregroundColor(.blue)
                                Text("Face ID / Touch ID")
                            }
                        }
                    }
                }
                
                Section(header: Text("Privacy")) {
                    NavigationLink(destination: PrivacySettingsView()) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.red)
                            Text("Privacy Settings")
                        }
                    }
                    
                    NavigationLink(destination: BlockedUsersView()) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .foregroundColor(.red)
                            Text("Blocked Users")
                        }
                    }
                }
                
                Section(header: Text("Security Alerts")) {
                    if let settings = settings,
                       let lastLogin = settings.lastLoginDate {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.gray)
                            VStack(alignment: .leading) {
                                Text("Last Login")
                                Text(formatDate(lastLogin))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    if let settings = settings {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(settings.failedLoginAttempts > 0 ? .red : .green)
                            VStack(alignment: .leading) {
                                Text("Failed Login Attempts")
                                Text("\(settings.failedLoginAttempts)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Security")
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            settings = UserDefaultsManager.shared.getUserSettings(for: currentUser.username)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TwoFactorSetupView: View {
    let isEnabled: Bool
    @Environment(\.dismiss) var dismiss
    @State private var verificationCode = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Status")) {
                HStack {
                    Image(systemName: isEnabled ? "checkmark.shield.fill" : "xmark.shield.fill")
                        .foregroundColor(isEnabled ? .green : .red)
                    Text(isEnabled ? "Two-Factor Authentication is enabled" : "Two-Factor Authentication is disabled")
                }
            }
            
            if !isEnabled {
                Section(header: Text("Setup")) {
                    Text("To enable two-factor authentication, you'll receive a verification code via SMS.")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button(action: requestVerificationCode) {
                        Text("Send Verification Code")
                    }
                    
                    SecureField("Enter Verification Code", text: $verificationCode)
                    
                    Button(action: verifyCode) {
                        Text("Enable Two-Factor Authentication")
                    }
                    .disabled(verificationCode.isEmpty)
                }
            } else {
                Section(header: Text("Disable")) {
                    Text("Disabling two-factor authentication will make your account less secure.")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Button(action: disableTwoFactor) {
                        Text("Disable Two-Factor Authentication")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Two-Factor Authentication")
        .alert("Two-Factor Authentication", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func requestVerificationCode() {
        // Implement SMS verification code sending
        alertMessage = "Verification code sent to your phone"
        showAlert = true
    }
    
    private func verifyCode() {
        // Implement verification code validation
        if verificationCode == "123456" { // Demo code
            if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
                UserDefaultsManager.shared.toggleTwoFactor(for: currentUser.username)
                alertMessage = "Two-Factor Authentication enabled successfully"
            }
        } else {
            alertMessage = "Invalid verification code"
        }
        showAlert = true
    }
    
    private func disableTwoFactor() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            UserDefaultsManager.shared.toggleTwoFactor(for: currentUser.username)
            alertMessage = "Two-Factor Authentication disabled"
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
            // Implement blocked users loading
            blockedUsers = ["demo_user1", "demo_user2"] // Demo data
        }
    }
    
    private func unblockUser(_ username: String) {
        if let index = blockedUsers.firstIndex(of: username) {
            blockedUsers.remove(at: index)
            // Implement unblock functionality
        }
    }
}
