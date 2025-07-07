import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showSignUp = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo and Title
            VStack(spacing: 16) {
                Image(systemName: "video.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("CreatorCast")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to manage your content")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            // Email Sign In Form
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("Sign In") {
                    signInWithEmail()
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty || isLoading)
            }
            .padding(.horizontal)
            
            // Divider
            HStack {
                VStack { Divider() }
                Text("or")
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                VStack { Divider() }
            }
            .padding(.horizontal)
            
            // Apple Sign In
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    authService.handleAppleSignIn(result: result)
                }
            )
            .frame(height: 45)
            .padding(.horizontal)
            
            Spacer()
            
            // Sign Up
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.secondary)
                
                Button("Sign Up") {
                    showSignUp = true
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .onReceive(authService.$authError) { error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                errorMessage = ""
            }
        }
    }
    
    private func signInWithEmail() {
        isLoading = true
        errorMessage = ""
        
        authService.signIn(email: email, password: password) { success in
            isLoading = false
            if !success {
                errorMessage = "Invalid email or password"
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthService.shared)
}