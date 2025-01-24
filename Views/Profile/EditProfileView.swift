import SwiftUI

struct EditProfileView: View {
    let user: UserDefaultsManager.User?
    @Environment(\.dismiss) var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var occupation = ""
    @State private var city = ""
    @State private var birthDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Occupation", text: $occupation)
                    TextField("City", text: $city)
                    DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveProfile()
                }
            )
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        guard let info = user?.personalInfo else { return }
        firstName = info.firstName
        lastName = info.lastName
        occupation = info.occupation ?? ""
        city = info.city ?? ""
        birthDate = info.birthDate
    }
    
    private func saveProfile() {
        guard var currentUser = user else { return }
        currentUser.personalInfo?.firstName = firstName
        currentUser.personalInfo?.lastName = lastName
        currentUser.personalInfo?.occupation = occupation
        currentUser.personalInfo?.city = city
        currentUser.personalInfo?.birthDate = birthDate
        
        UserDefaultsManager.shared.updateCurrentUser(user: currentUser)
        dismiss()
    }
}
