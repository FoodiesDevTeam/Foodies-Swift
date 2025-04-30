import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authViewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var navigateToPersonalInfo = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo
                Image("FoodiesLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                
                // Title
                Text(LanguageManager.shared.localizedString("welcome_to_foodies"))
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Sign Up Form
                VStack(spacing: 20) {
                    TextField(LanguageManager.shared.localizedString("email_placeholder"), text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    
                    SecureField(LanguageManager.shared.localizedString("password_placeholder"), text: $password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    
                    SecureField(LanguageManager.shared.localizedString("confirm_password_placeholder"), text: $confirmPassword)
                        .textContentType(.newPassword)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }
                .padding()
                
                // Sign Up Button
                Button(action: signUp) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(LanguageManager.shared.localizedString("sign_up"))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(isLoading)
                
                // Sign In Link
                Button(action: {
                    dismiss()
                }) {
                    Text(LanguageManager.shared.localizedString("have_account"))
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationBarHidden(true)
            .alert(LanguageManager.shared.localizedString("error_title"), isPresented: $showAlert) {
                Button(LanguageManager.shared.localizedString("ok_button"), role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .fullScreenCover(isPresented: $navigateToPersonalInfo) {
                OnboardingView()
            }
        }
    }
    
    private func signUp() {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            alertMessage = LanguageManager.shared.localizedString("error_empty_fields")
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = LanguageManager.shared.localizedString("error_passwords_dont_match")
            showAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await authViewModel.signUp(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    navigateToPersonalInfo = true
                }
            } catch let error as SupabaseError {
                await MainActor.run {
                    switch error {
                    case .clientError(let message):
                        alertMessage = message
                    default:
                        alertMessage = LanguageManager.shared.localizedString("error_sign_up")
                    }
                    showAlert = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Signup Error: \(error)")
                    alertMessage = LanguageManager.shared.localizedString("error_sign_up")
                    showAlert = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    SignUpView()
}
