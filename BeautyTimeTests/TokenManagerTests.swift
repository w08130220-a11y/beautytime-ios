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
}
