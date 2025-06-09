import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isShowingTerms = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 20)
                
                Text("Documents App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.username)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                }
                .padding(.horizontal)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    Task {
                        await login()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(username.isEmpty || password.isEmpty || isLoading)
                
                Button(action: {
                    isShowingTerms = true
                }) {
                    Text("Terms and Conditions")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingTerms) {
                TermsAndConditionsView()
            }
        }
    }
    
    private func login() async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authService.login(username: username, password: password)
        } catch AuthenticationError.invalidCredentials {
            errorMessage = "Invalid username or password"
        } catch AuthenticationError.networkError {
            errorMessage = "Network error. Please check your connection"
        } catch {
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
}

#Preview {
    LoginView()
} 
