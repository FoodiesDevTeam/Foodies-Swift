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
            
            // Login Form
            VStack(spacing: 20) {
                TextField("E-posta", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                
                SecureField("Şifre", text: $password)
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
                    Text("Giriş Yap")
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
            NavigationLink("Hesabınız yok mu? Kayıt olun", destination: SignUpView())
                .foregroundColor(.blue)
        }
        .padding()
        .alert("Hata", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .fullScreenCover(isPresented: $isAuthenticated) {
            MainTabView()
        }
    }
    
    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Lütfen e-posta ve şifrenizi girin"
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
                    alertMessage = "Giriş yapılamadı: \(error.localizedDescription)"
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
