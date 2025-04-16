import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedLanguage: LanguageManager.Language
    var onLogout: () -> Void
    
    init(onLogout: @escaping () -> Void) {
        self.onLogout = onLogout
        _selectedLanguage = State(initialValue: LanguageManager.shared.currentLanguage)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text(LanguageManager.shared.localizedString("language"))) {
                    Picker("", selection: $selectedLanguage) {
                        Text(LanguageManager.shared.localizedString("english"))
                            .tag(LanguageManager.Language.english)
                        Text(LanguageManager.shared.localizedString("turkish"))
                            .tag(LanguageManager.Language.turkish)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedLanguage) { newValue in
                        LanguageManager.shared.currentLanguage = newValue
                    }
                }
                
                Section {
                    Button(action: onLogout) {
                        HStack {
                            Text(LanguageManager.shared.localizedString("logout"))
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle(LanguageManager.shared.localizedString("settings"))
            .navigationBarItems(leading: Button(LanguageManager.shared.localizedString("close")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
} 
