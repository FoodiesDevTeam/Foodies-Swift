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
                Text("Foodies App'e Hoş Geldiniz")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Sign Up Form
                VStack(spacing: 20) {
                    TextField("E-posta", text: $email)
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
                    
                    SecureField("Şifre", text: $password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    
                    SecureField("Şifre Tekrar", text: $confirmPassword)
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
                        Text("Kayıt Ol")
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
                    Text("Hesabınız var mı? Giriş yapın")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationBarHidden(true)
            .alert("Hata", isPresented: $showAlert) {
                Button("Tamam", role: .cancel) { }
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
            alertMessage = "Lütfen tüm alanları doldurun"
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Şifreler eşleşmiyor"
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
                        alertMessage = "Kayıt işlemi sırasında bir hata oluştu. Lütfen tekrar deneyin."
                    }
                    showAlert = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Signup Error: \(error)")
                    alertMessage = "Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin."
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
