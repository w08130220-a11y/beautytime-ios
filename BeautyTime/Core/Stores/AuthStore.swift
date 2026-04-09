import Foundation
import SwiftUI

@MainActor
@Observable
class AuthStore {
    var isAuthenticated = false
    var currentUser: User?
    var isLoading = false
    var error: String?

    // OTP flow
    var otpSent = false
    var otpEmail = ""

    private let api = APIClient.shared
    private let tokenManager = TokenManager.shared

    /// State parameter for LINE OAuth CSRF protection
    var pendingOAuthState: String?

    // nonisolated(unsafe) 讓 deinit（非 actor 隔離）可存取此屬性
    nonisolated(unsafe) private var tokenExpiryObserver: Any?

    init() {
        isAuthenticated = tokenManager.hasToken

        // 監聽 token 過期通知，回呼使用 Task 跳回 MainActor 執行 signOut
        tokenExpiryObserver = NotificationCenter.default.addObserver(
            forName: .authTokenExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.signOut()
            }
        }
    }

    deinit {
        if let observer = tokenExpiryObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Email OTP

    func sendOTP(email: String, type: String = "login", fullName: String? = nil) async {
        isLoading = true
        error = nil
        do {
            var body: [String: Any] = ["email": email, "type": type]
            if let fullName { body["fullName"] = fullName }

            let _: OTPResponse = try await api.post(
                path: APIEndpoints.Auth.sendOTP,
                body: JSONBody(body)
            )
            otpEmail = email
            otpSent = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func verifyOTP(email: String, otp: String) async {
        isLoading = true
        error = nil
        do {
            let response: AuthResponse = try await api.post(
                path: APIEndpoints.Auth.verifyOTP,
                body: ["email": email, "code": otp]
            )
            handleAuthResponse(response)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - OAuth

    func signInWithApple(identityToken: String, authorizationCode: String, fullName: String?) async {
        isLoading = true
        error = nil
        do {
            var dict: [String: Any] = [
                "identityToken": identityToken,
                "authorizationCode": authorizationCode
            ]
            if let fullName { dict["fullName"] = fullName }

            let response: AuthResponse = try await api.post(
                path: APIEndpoints.Auth.apple,
                body: JSONBody(dict)
            )
            handleAuthResponse(response)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func signInWithGoogle(idToken: String) async {
        print("[Auth][Google] signInWithGoogle 開始, thread=\(Thread.isMainThread ? "main" : "bg")")
        isLoading = true
        error = nil
        do {
            let response: AuthResponse = try await api.post(
                path: APIEndpoints.Auth.google,
                body: JSONBody(["idToken": idToken])
            )
            print("[Auth][Google] API 回應成功, token=\(response.token != nil ? "有" : "無"), user=\(response.user?.email ?? "nil")")
            handleAuthResponse(response)
        } catch {
            print("[Auth][Google] API 錯誤: \(error)")
            self.error = error.localizedDescription
        }
        print("[Auth][Google] 結束, isAuthenticated=\(isAuthenticated), thread=\(Thread.isMainThread ? "main" : "bg")")
        isLoading = false
    }

    /// Generate a state parameter for LINE OAuth. Call before opening the OAuth URL.
    func generateOAuthState() -> String {
        let state = UUID().uuidString
        pendingOAuthState = state
        return state
    }

    func signInWithLINE(code: String, redirectUri: String, state: String? = nil) async {
        isLoading = true
        error = nil

        // Validate OAuth state to prevent CSRF — mandatory check
        guard let expectedState = pendingOAuthState,
              let receivedState = state,
              receivedState == expectedState else {
            self.error = "登入驗證失敗，請重新嘗試"
            isLoading = false
            pendingOAuthState = nil
            return
        }
        pendingOAuthState = nil

        do {
            let response: AuthResponse = try await api.post(
                path: APIEndpoints.Auth.line,
                body: JSONBody(["code": code, "redirectUri": redirectUri])
            )
            handleAuthResponse(response)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Session

    func fetchCurrentUser() async {
        guard tokenManager.hasToken else { return }
        do {
            let user: User = try await api.get(path: APIEndpoints.Auth.me)
            self.currentUser = user
            self.isAuthenticated = true
            #if DEBUG
            print("[Auth] User loaded: role=\(user.role), email=\(user.email)")
            #endif
        } catch let apiError as APIError {
            if case .unauthorized = apiError {
                signOut()
            } else {
                #if DEBUG
                print("[Auth] fetchCurrentUser failed: \(apiError)")
                #endif
            }
        } catch {
            #if DEBUG
            print("[Auth] fetchCurrentUser unexpected error: \(error)")
            #endif
        }
    }

    func checkEmail(_ email: String) async -> Bool {
        do {
            let response: EmailCheckResponse = try await api.get(
                path: APIEndpoints.Auth.checkEmail,
                queryItems: [URLQueryItem(name: "email", value: email)]
            )
            return response.exists
        } catch {
            return false
        }
    }

    func signOut() {
        tokenManager.deleteToken()
        currentUser = nil
        isAuthenticated = false
        otpSent = false
        otpEmail = ""
    }

    // MARK: - Private

    private func handleAuthResponse(_ response: AuthResponse) {
        print("[Auth] handleAuthResponse, token=\(response.token != nil ? "有" : "無"), user=\(response.user?.email ?? "nil"), thread=\(Thread.isMainThread ? "main" : "bg")")
        if let token = response.token {
            tokenManager.saveToken(token)
            print("[Auth] token 已儲存, 設定 isAuthenticated = true")
            isAuthenticated = true
            print("[Auth] isAuthenticated 設定完成: \(isAuthenticated)")
        } else {
            print("[Auth] ⚠️ response 沒有 token！isAuthenticated 不會更新")
        }
        if let user = response.user {
            currentUser = user
        }
    }
}
