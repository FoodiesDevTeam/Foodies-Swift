import SwiftUI

struct SignUpView: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    var body: some View {
        VStack(spacing: 40) {
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
                // Sign up action
                // TODO: Implement authentication
                NavigationUtil.navigate(to: CreateProfileView())
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
    }
}

#Preview {
    NavigationView {
        SignUpView()
    }
} 
