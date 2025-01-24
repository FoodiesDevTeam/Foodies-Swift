import SwiftUI

struct SignUpView: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToProfile = false
    @State private var showMainView = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 40) {
            // Logo
            Image("foodies-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        logoScale = 1.0
                        logoOpacity = 1.0
                    }
                }
            
            // Sign Up Text
            Text("Sign Up")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Username Field
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.gray)
                    TextField("Username", text: $username)
                }
                Divider()
            }
            .padding(.horizontal)
            
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.gray)
                    TextField("Email", text: $email)
                }
                Divider()
            }
            .padding(.horizontal)
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.gray)
                    SecureField("Password", text: $password)
                }
                Divider()
            }
            .padding(.horizontal)
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.gray)
                    SecureField("Confirm password", text: $confirmPassword)
                }
                Divider()
            }
            .padding(.horizontal)
            
            // Sign up Button
            Button(action: {
                if password != confirmPassword {
                    alertMessage = "Passwords do not match"
                    showAlert = true
                    return
                }
                
                if UserDefaultsManager.shared.userExists(username: username) {
                    alertMessage = "Username already exists"
                    showAlert = true
                    return
                }
                
                let user = UserDefaultsManager.User(
                    username: username,
                    email: email,
                    password: password
                )
                
                UserDefaultsManager.shared.saveUser(user)
                UserDefaultsManager.shared.setCurrentUser(username: username)
                navigateToProfile = true
            }) {
                Text("Sign up")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Sign In Link
            HStack {
                Text("Already a Member?")
                    .foregroundColor(.gray)
                NavigationLink(destination: SignInView()) {
                    Text("Sign In")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.top, 100)
        .navigationBarHidden(true)
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .fullScreenCover(isPresented: $navigateToProfile) {
            NavigationView {
                PersonalInfoView()
            }
        }
        .fullScreenCover(isPresented: $showMainView) {
            MainTabView()
        }
    }
}

#Preview {
    NavigationView {
        SignUpView()
    }
}
