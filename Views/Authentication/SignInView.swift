import SwiftUI

struct SignInView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isAuthenticated = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Sign In Text
            Text("Sign In")
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
            
            // Sign in Button
            Button(action: {
                if UserDefaultsManager.shared.authenticateUser(username: username, password: password) {
                    isAuthenticated = true
                } else {
                    alertMessage = "Invalid username or password"
                    showAlert = true
                }
            }) {
                Text("Sign in")
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
            
            // Forgot Password
            Button(action: {
                // Forgot password action
            }) {
                Text("Forgot Password?")
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Sign Up Link
            NavigationLink(destination: SignUpView()) {
                Text("Sign Up")
                    .foregroundColor(.pink)
            }
        }
        .padding(.top, 100)
        .navigationBarHidden(true)
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .fullScreenCover(isPresented: $isAuthenticated) {
            ContentView()
        }
    }
}

#Preview {
    NavigationView {
        SignInView()
    }
} 
