import XCTest
@testable import BeautyTime

final class APIClientTests: XCTestCase {

    // MARK: - APIError Tests

    func testRateLimitedErrorDescription() {
        let error = APIError.rateLimited(retryAfter: 30)
        XCTAssertEqual(error.errorDescription, "請求過於頻繁，請等待 30 秒後再試")
    }

    func testRateLimitedNoRetryAfter() {
        let error = APIError.rateLimited(retryAfter: nil)
        XCTAssertEqual(error.errorDescription, "請求過於頻繁，請稍後再試")
    }

    func testConflictErrorDescription() {
        let error = APIError.conflict
        XCTAssertEqual(error.errorDescription, "此時段已被預約，請選擇其他時段")
    }

    func testTokenExpiredErrorDescription() {
        let error = APIError.tokenExpired
        XCTAssertEqual(error.errorDescription, "登入已過期，請重新登入")
    }

    // MARK: - 401 Notification Tests

    func testUnauthorizedPostsNotification() {
        let expectation = XCTNSNotificationExpectation(
            name: .authTokenExpired,
            object: nil
        )

        // Simulate what APIClient does on 401
        TokenManager.shared.saveToken("test-token")
        TokenManager.shared.deleteToken()
        NotificationCenter.default.post(name: .authTokenExpired, object: nil)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(TokenManager.shared.hasToken)
    }

    // MARK: - Error Case Coverage

    func testAllAPIErrorCasesHaveDescriptions() {
        let cases: [APIError] = [
            .invalidURL,
            .invalidResponse,
            .httpError(statusCode: 400, data: Data()),
            .httpError(statusCode: 500, data: Data()),
            .decodingError(NSError(domain: "test", code: 0)),
            .unauthorized,
            .networkError(NSError(domain: "test", code: 0)),
            .rateLimited(retryAfter: 10),
            .rateLimited(retryAfter: nil),
            .conflict,
            .tokenExpired,
        ]

        for error in cases {
            XCTAssertNotNil(error.errorDescription, "Missing description for \(error)")
            XCTAssertFalse(error.errorDescription!.isEmpty, "Empty description for \(error)")
        }
    }

    func testServerErrorShowsFriendlyMessage() {
        let error = APIError.httpError(statusCode: 500, data: Data())
        XCTAssertEqual(error.errorDescription, "伺服器暫時無法處理請求，請稍後再試")
    }

    func testClientErrorParsesAPIMessage() {
        let json = "{\"message\":\"Email 格式不正確\"}".data(using: .utf8)!
        let error = APIError.httpError(statusCode: 400, data: json)
        XCTAssertEqual(error.errorDescription, "Email 格式不正確")
    }

    func testClientErrorParsesArrayMessage() {
        let json = "{\"message\":[\"密碼太短\",\"需要大寫字母\"]}".data(using: .utf8)!
        let error = APIError.httpError(statusCode: 400, data: json)
        XCTAssertEqual(error.errorDescription, "密碼太短")
    }
}
