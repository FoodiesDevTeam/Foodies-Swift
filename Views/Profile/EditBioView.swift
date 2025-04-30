import SwiftUI

struct EditBioView: View {
    @Environment(\.dismiss) var dismiss
    @State private var bioText: String
    var onSave: (String) -> Void
    
    init(currentBio: String, onSave: @escaping (String) -> Void) {
        _bioText = State(initialValue: currentBio)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $bioText)
                    .frame(height: 200)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                
                Spacer()
            }
            .navigationTitle(LanguageManager.shared.localizedString("Bio Düzenle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LanguageManager.shared.localizedString("cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LanguageManager.shared.localizedString("save")) {
                        onSave(bioText)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EditBioView(currentBio: "Örnek biyografi metni", onSave: { _ in })
} 
