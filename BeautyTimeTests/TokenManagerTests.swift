import XCTest
@testable import BeautyTime

final class TokenManagerTests: XCTestCase {

    private let tokenManager = TokenManager.shared

    override func setUp() {
        super.setUp()
        tokenManager.deleteToken()
    }

    override func tearDown() {
        tokenManager.deleteToken()
        super.tearDown()
    }

    func testInitialStateHasNoToken() {
        tokenManager.deleteToken()
        XCTAssertNil(tokenManager.getToken())
        XCTAssertFalse(tokenManager.hasToken)
    }

    func testSaveAndRetrieveToken() {
        tokenManager.saveToken("test-jwt-token")
        XCTAssertEqual(tokenManager.getToken(), "test-jwt-token")
        XCTAssertTrue(tokenManager.hasToken)
    }

    func testDeleteToken() {
        tokenManager.saveToken("test-token")
        XCTAssertTrue(tokenManager.hasToken)

        tokenManager.deleteToken()
        XCTAssertNil(tokenManager.getToken())
        XCTAssertFalse(tokenManager.hasToken)
    }

    func testOverwriteToken() {
        tokenManager.saveToken("token-1")
        XCTAssertEqual(tokenManager.getToken(), "token-1")

        tokenManager.saveToken("token-2")
        XCTAssertEqual(tokenManager.getToken(), "token-2")
    }

    // MARK: - JWT Expiry Tests

    /// Helper: create a JWT with a given exp timestamp
    private func makeJWT(exp: TimeInterval) -> String {
        let header = Data("{\"alg\":\"HS256\",\"typ\":\"JWT\"}".utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let payload = Data("{\"sub\":\"1\",\"exp\":\(Int(exp))}".utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "\(header).\(payload).fakesignature"
    }

    func testExpiredTokenIsDetected() {
        let pastExp = Date().timeIntervalSince1970 - 3600 // 1 hour ago
        tokenManager.saveToken(makeJWT(exp: pastExp))
        XCTAssertTrue(tokenManager.isTokenExpired())
    }

    func testValidTokenIsNotExpired() {
        let futureExp = Date().timeIntervalSince1970 + 3600 // 1 hour from now
        tokenManager.saveToken(makeJWT(exp: futureExp))
        XCTAssertFalse(tokenManager.isTokenExpired())
    }

    func testTokenExpiringSoonIsDetected() {
        // Expires in 4 minutes (within 5-minute buffer)
        let soonExp = Date().timeIntervalSince1970 + 240
        tokenManager.saveToken(makeJWT(exp: soonExp))
        XCTAssertTrue(tokenManager.isTokenExpired())
    }

    func testNoTokenIsNotExpired() {
        tokenManager.deleteToken()
        XCTAssertFalse(tokenManager.isTokenExpired())
    }

    func testTokenExpiryDate() {
        let exp = Date().timeIntervalSince1970 + 7200
        tokenManager.saveToken(makeJWT(exp: exp))
        let expiryDate = tokenManager.tokenExpiryDate()
        XCTAssertNotNil(expiryDate)
        XCTAssertEqual(expiryDate!.timeIntervalSince1970, exp, accuracy: 1.0)
    }

    func testInvalidTokenReturnsNilExpiryDate() {
        tokenManager.saveToken("not-a-jwt")
        XCTAssertNil(tokenManager.tokenExpiryDate())
        XCTAssertFalse(tokenManager.isTokenExpired()) // graceful fallback
    }
}
