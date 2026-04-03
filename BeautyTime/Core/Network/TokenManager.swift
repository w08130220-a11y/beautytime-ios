import Foundation
import KeychainAccess

class TokenManager {
    static let shared = TokenManager()

    private let keychain = Keychain(service: "com.beautytime.ios")
    private let tokenKey = "jwt_token"

    private init() {}

    func getToken() -> String? {
        try? keychain.get(tokenKey)
    }

    func saveToken(_ token: String) {
        try? keychain.set(token, key: tokenKey)
    }

    func deleteToken() {
        try? keychain.remove(tokenKey)
    }

    var hasToken: Bool {
        getToken() != nil
    }
}
