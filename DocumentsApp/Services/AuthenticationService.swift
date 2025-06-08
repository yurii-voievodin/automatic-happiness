import Foundation

enum AuthenticationError: Error {
    case invalidCredentials
    case networkError(Error)
    case invalidResponse
    case tokenNotFound
}

@MainActor
class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    private init() {}
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    
    private let baseURL = "https://dummyjson.com/auth"
    private let keychainService = KeychainService.shared
    
    private enum TokenKey {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }
    
    func login(username: String, password: String) async throws {
        let credentials = LoginCredentials(username: username, password: password)
        let url = URL(string: "\(baseURL)/login")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpShouldHandleCookies = true
        request.httpBody = try JSONEncoder().encode(credentials)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw AuthenticationError.invalidCredentials
            }
            
            let user = try JSONDecoder().decode(User.self, from: data)
            
            // Save tokens to keychain
            try keychainService.saveToken(user.accessToken, forKey: TokenKey.accessToken)
            try keychainService.saveToken(user.refreshToken, forKey: TokenKey.refreshToken)
            
            currentUser = user
            isAuthenticated = true
        } catch let error as DecodingError {
            print(error)
            throw AuthenticationError.invalidResponse
        } catch {
            throw AuthenticationError.networkError(error)
        }
    }
    
    func logout() {
        do {
            try keychainService.clearAllTokens()
            currentUser = nil
            isAuthenticated = false
        } catch {
            print("Error clearing tokens: \(error)")
        }
    }
    
    func checkAuthentication() async {
        do {
            let accessToken = try keychainService.getToken(forKey: TokenKey.accessToken)
            // Here you would typically validate the token with your backend
            // For now, we'll just check if it exists
            isAuthenticated = !accessToken.isEmpty
        } catch {
            isAuthenticated = false
        }
    }
    
    func getAccessToken() throws -> String {
        try keychainService.getToken(forKey: TokenKey.accessToken)
    }
}
