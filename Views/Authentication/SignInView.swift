import SwiftUI

struct SignInView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var isAuthenticated = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image("FoodiesLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            
            Text(LanguageManager.shared.localizedString("welcome_to_foodies"))
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                TextField(LanguageManager.shared.localizedString("email_placeholder"), text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                
                SecureField(LanguageManager.shared.localizedString("password_placeholder"), text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
            }
            .padding()
            
            // Sign in Button
            Button(action: signIn) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(LanguageManager.shared.localizedString("sign_in"))
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
            
            // Sign up link
            NavigationLink(LanguageManager.shared.localizedString("no_account"), destination: SignUpView())
                .foregroundColor(.blue)
        }
        .padding()
        .alert(LanguageManager.shared.localizedString("error_title"), isPresented: $showAlert) {
            Button(LanguageManager.shared.localizedString("ok_button"), role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .fullScreenCover(isPresented: $isAuthenticated) {
            MainTabView()
        }
    }
    
    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = LanguageManager.shared.localizedString("error_empty_fields")
            showAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await authViewModel.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                    isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = String(format: LanguageManager.shared.localizedString("error_sign_in"), error.localizedDescription)
                    showAlert = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        SignInView()
    }
} 
