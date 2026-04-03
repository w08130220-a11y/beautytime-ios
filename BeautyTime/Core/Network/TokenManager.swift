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

    // MARK: - JWT Expiry Detection

    /// Returns true if the token is expired or will expire within 5 minutes.
    /// Returns false if token is nil or payload cannot be decoded (let server decide).
    func isTokenExpired() -> Bool {
        guard let expiryDate = tokenExpiryDate() else { return false }
        let bufferSeconds: TimeInterval = 300 // 5 minutes
        return Date().addingTimeInterval(bufferSeconds) >= expiryDate
    }

    /// Extracts the expiry date from the JWT payload. Returns nil if decode fails.
    func tokenExpiryDate() -> Date? {
        guard let token = getToken() else { return nil }
        let segments = token.split(separator: ".")
        guard segments.count >= 2 else { return nil }

        var base64 = String(segments[1])
        // Base64URL → Base64: replace URL-safe chars and pad
        base64 = base64.replacingOccurrences(of: "-", with: "+")
                       .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let payloadData = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: exp)
    }
}
