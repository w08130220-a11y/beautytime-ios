import XCTest
@testable import BeautyTime

final class AuthStoreTests: XCTestCase {

    private var authStore: AuthStore!

    override func setUp() {
        super.setUp()
        TokenManager.shared.deleteToken()
        authStore = AuthStore()
    }

    override func tearDown() {
        TokenManager.shared.deleteToken()
        authStore = nil
        super.tearDown()
    }

    // MARK: - Token Expiry Listener

    func testSignsOutOnTokenExpiredNotification() {
        // Simulate logged-in state
        TokenManager.shared.saveToken("some-token")
        authStore = AuthStore()
        XCTAssertTrue(authStore.isAuthenticated)

        // Post token expired notification
        NotificationCenter.default.post(name: .authTokenExpired, object: nil)

        // Give RunLoop a tick to process the notification
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        XCTAssertFalse(authStore.isAuthenticated)
        XCTAssertNil(authStore.currentUser)
        XCTAssertFalse(TokenManager.shared.hasToken)
    }

    // MARK: - OAuth State Validation

    func testGenerateOAuthStateReturnsUUID() {
        let state = authStore.generateOAuthState()
        XCTAssertFalse(state.isEmpty)
        XCTAssertNotNil(UUID(uuidString: state))
        XCTAssertEqual(authStore.pendingOAuthState, state)
    }

    func testGenerateOAuthStateChangesEachTime() {
        let state1 = authStore.generateOAuthState()
        let state2 = authStore.generateOAuthState()
        XCTAssertNotEqual(state1, state2)
    }

    func testLINESignInRejectsStateMismatch() async {
        let _ = authStore.generateOAuthState()

        // Call with wrong state
        await authStore.signInWithLINE(
            code: "test-code",
            redirectUri: "https://example.com/callback",
            state: "wrong-state"
        )

        XCTAssertNotNil(authStore.error)
        XCTAssertEqual(authStore.error, "登入驗證失敗，請重新嘗試")
        XCTAssertFalse(authStore.isAuthenticated)
        XCTAssertNil(authStore.pendingOAuthState) // Cleared after check
    }

    func testLINESignInRejectsNilState() async {
        let _ = authStore.generateOAuthState()

        // Call without state
        await authStore.signInWithLINE(
            code: "test-code",
            redirectUri: "https://example.com/callback",
            state: nil
        )

        XCTAssertNotNil(authStore.error)
        XCTAssertEqual(authStore.error, "登入驗證失敗，請重新嘗試")
    }

    // MARK: - Initial State

    func testInitialStateWithNoToken() {
        TokenManager.shared.deleteToken()
        let store = AuthStore()
        XCTAssertFalse(store.isAuthenticated)
        XCTAssertNil(store.currentUser)
        XCTAssertFalse(store.otpSent)
        XCTAssertTrue(store.otpEmail.isEmpty)
    }

    func testInitialStateWithToken() {
        TokenManager.shared.saveToken("existing-token")
        let store = AuthStore()
        XCTAssertTrue(store.isAuthenticated)
    }

    func testSignOutClearsAllState() {
        TokenManager.shared.saveToken("test-token")
        authStore = AuthStore()
        authStore.signOut()

        XCTAssertFalse(authStore.isAuthenticated)
        XCTAssertNil(authStore.currentUser)
        XCTAssertFalse(authStore.otpSent)
        XCTAssertTrue(authStore.otpEmail.isEmpty)
        XCTAssertFalse(TokenManager.shared.hasToken)
    }
}
