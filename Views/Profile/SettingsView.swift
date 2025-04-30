import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var languageManager: LanguageManager
    var onLogout: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                // Dil Seçimi
                Section(header: Text("language")) {
                    ForEach(Language.allCases, id: \.self) { language in
                        Button(action: {
                            languageManager.changeLanguage(to: language)
                        }) {
                            HStack {
                                Text(language == .tr ? "turkish" : "english")
                                Spacer()
                                if languageManager.currentLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                // Bildirimler
                Section(header: Text("notifications")) {
                    Toggle("notifications", isOn: .constant(true))
                }
                
                // Gizlilik ve Yardım
                Section(header: Text("privacy")) {
                    NavigationLink(destination: Text("privacy_policy")) {
                        Text("privacy_policy")
                    }
                    NavigationLink(destination: Text("terms")) {
                        Text("terms")
                    }
                    NavigationLink(destination: Text("help")) {
                        Text("help")
                    }
                }
                
                // Uygulama Bilgileri
                Section(header: Text("about")) {
                    HStack {
                        Text("version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    NavigationLink(destination: Text("contact_us")) {
                        Text("contact_us")
                    }
                }
                
                // Çıkış Yap
                Section {
                    Button(action: onLogout) {
                        Text("logout")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("settings")
            .navigationBarItems(trailing: Button("done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    SettingsView(onLogout: {})
        .environmentObject(LanguageManager.shared)
} 