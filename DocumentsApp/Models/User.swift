import Foundation

struct User: Codable {
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let gender: String
    let image: String
    let accessToken: String
    let refreshToken: String
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

struct LoginCredentials: Codable {
    let username: String
    let password: String
    let expiresInMins: Int?
    
    init(username: String, password: String, expiresInMins: Int = 60) {
        self.username = username
        self.password = password
        self.expiresInMins = expiresInMins
    }
} 