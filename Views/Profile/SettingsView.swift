import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showPasswordChange = false
    @State private var showReportSheet = false
    @State private var settings: UserDefaultsManager.UserSettings?
    @State private var reportText = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    if let settings = settings {
                        Toggle(isOn: Binding(
                            get: { settings.isVisible },
                            set: { newValue in
                                toggleSetting(\.isVisible)
                            }
                        )) {
                            SettingsRow(icon: "eye.fill", title: "Visibility", color: .blue)
                        }
                        
                        Toggle(isOn: Binding(
                            get: { settings.notificationsEnabled },
                            set: { newValue in
                                toggleSetting(\.notificationsEnabled)
                            }
                        )) {
                            SettingsRow(icon: "bell.fill", title: "Notifications", color: .purple)
                        }
                        
                        Toggle(isOn: Binding(
                            get: { settings.alertsEnabled },
                            set: { newValue in
                                toggleSetting(\.alertsEnabled)
                            }
                        )) {
                            SettingsRow(icon: "speaker.wave.2.fill", title: "Alerts", color: .orange)
                        }
                        
                        Toggle(isOn: Binding(
                            get: { settings.cloudSyncEnabled },
                            set: { newValue in
                                toggleSetting(\.cloudSyncEnabled)
                            }
                        )) {
                            SettingsRow(icon: "cloud.fill", title: "Cloud Sync", color: .blue)
                        }
                        
                        Toggle(isOn: Binding(
                            get: { settings.statisticsEnabled },
                            set: { newValue in
                                toggleSetting(\.statisticsEnabled)
                            }
                        )) {
                            SettingsRow(icon: "chart.bar.fill", title: "Statistic Reports", color: .green)
                        }
                    }
                }
                
                Section(header: Text("Security")) {
                    if let settings = settings {
                        Toggle(isOn: Binding(
                            get: { settings.privacyEnabled },
                            set: { newValue in
                                toggleSetting(\.privacyEnabled)
                            }
                        )) {
                            SettingsRow(icon: "hand.raised.fill", title: "Privacy", color: .red)
                        }
                        
                        Toggle(isOn: Binding(
                            get: { settings.securityEnabled },
                            set: { newValue in
                                toggleSetting(\.securityEnabled)
                            }
                        )) {
                            SettingsRow(icon: "lock.fill", title: "Security", color: .red)
                        }
                        
                        Toggle(isOn: Binding(
                            get: { settings.twoFactorEnabled },
                            set: { newValue in
                                if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
                                    UserDefaultsManager.shared.toggleTwoFactor(for: currentUser.username)
                                    loadSettings()
                                }
                            }
                        )) {
                            SettingsRow(icon: "key.fill", title: "Two-Factor Authentication", color: .yellow)
                        }
                        
                        Button(action: { showPasswordChange = true }) {
                            SettingsRow(icon: "lock.rotation", title: "Change Password", color: .blue)
                        }
                    }
                }
                
                Section(header: Text("Support")) {
                    Button(action: { showReportSheet = true }) {
                        SettingsRow(icon: "exclamationmark.triangle.fill", title: "Report to Admin", color: .orange)
                    }
                    
                    if let settings = settings,
                       let lastLogin = settings.lastLoginDate {
                        HStack {
                            SettingsRow(icon: "clock.fill", title: "Last Login", color: .gray)
                            Spacer()
                            Text(formatDate(lastLogin))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section {
                    Button(action: { showLogoutAlert = true }) {
                        SettingsRow(icon: "arrow.right.square.fill", title: "Logout", color: .red)
                    }
                    
                    Button(action: { showDeleteAccountAlert = true }) {
                        SettingsRow(icon: "trash.fill", title: "Delete Account", color: .red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showPasswordChange) {
            ChangePasswordView()
        }
        .sheet(isPresented: $showReportSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Report Details")) {
                        TextEditor(text: $reportText)
                            .frame(height: 150)
                    }
                }
                .navigationTitle("Report to Admin")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showReportSheet = false
                    },
                    trailing: Button("Send") {
                        sendReport()
                        showReportSheet = false
                    }
                )
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
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
    
    private func toggleSetting<T>(_ keyPath: WritableKeyPath<UserDefaultsManager.UserSettings, T>) where T == Bool {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser(),
           var currentSettings = settings {
            currentSettings[keyPath: keyPath].toggle()
            UserDefaultsManager.shared.updateUserSettings(currentSettings, for: currentUser.username)
            loadSettings()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func sendReport() {
        // Implement report sending logic
        reportText = ""
    }
    
    private func logout() {
        UserDefaultsManager.shared.logout()
        // Navigate to login screen
    }
    
    private func deleteAccount() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            UserDefaultsManager.shared.deleteUser(username: currentUser.username)
        }
        // Navigate to login screen
    }
}

struct SettingsRow: View {
    var icon: String
    var title: String
    var color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Password")) {
                    SecureField("Enter current password", text: $currentPassword)
                }
                
                Section(header: Text("New Password")) {
                    SecureField("Enter new password", text: $newPassword)
                    SecureField("Confirm new password", text: $confirmPassword)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    changePassword()
                }
            )
            .alert("Password Change", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage == "Password changed successfully" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func changePassword() {
        guard let currentUser = UserDefaultsManager.shared.getCurrentUser() else {
            alertMessage = "User not found"
            showAlert = true
            return
        }
        
        // Validate current password
        if currentUser.password != currentPassword {
            alertMessage = "Current password is incorrect"
            showAlert = true
            return
        }
        
        // Validate new password
        if newPassword.isEmpty {
            alertMessage = "New password cannot be empty"
            showAlert = true
            return
        }
        
        if newPassword != confirmPassword {
            alertMessage = "New passwords do not match"
            showAlert = true
            return
        }
        
        // Update password
        UserDefaultsManager.shared.updatePassword(for: currentUser.username, newPassword: newPassword)
        alertMessage = "Password changed successfully"
        showAlert = true
    }
}
