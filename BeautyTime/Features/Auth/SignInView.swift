import AuthenticationServices
import GoogleSignIn
import SwiftUI

struct SignInView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var email = ""
    @State private var showSignUp = false
    @State private var showOTP = false

    private var isEmailValid: Bool {
        let pattern = /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/
        return email.wholeMatch(of: pattern) != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 40)

                // MARK: - Logo & Title
                logoSection

                Spacer().frame(height: 8)

                // MARK: - Email OTP Section
                emailSection

                // MARK: - Divider
                dividerSection

                // MARK: - Social Sign In
                socialSignInSection

                // MARK: - Sign Up Link
                signUpLink

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("登入")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showOTP) {
            NavigationStack {
                OTPInputView(email: email)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSignUp) {
            NavigationStack {
                SignUpView()
            }
        }
        .onChange(of: authStore.otpSent) { _, sent in
            if sent {
                showOTP = true
            }
        }
        .alert("錯誤", isPresented: Binding<Bool>(
            get: { authStore.error != nil },
            set: { if !$0 { authStore.error = nil } }
        )) {
            Button("確定") { authStore.error = nil }
        } message: {
            Text(authStore.error ?? "")
        }
    }

    // MARK: - Subviews

    private var logoSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.pink)

            Text("BeautyTime")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("美麗從這裡開始")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var emailSection: some View {
        VStack(spacing: 16) {
            TextField("電子信箱", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                Task {
                    await authStore.sendOTP(email: email)
                }
            } label: {
                HStack(spacing: 8) {
                    if authStore.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("發送驗證碼")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isEmailValid && !authStore.isLoading ? Color.pink : Color.pink.opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isEmailValid || authStore.isLoading)
        }
    }

    private var dividerSection: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color(.systemGray4))
            Text("或使用以下方式登入")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .layoutPriority(1)
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color(.systemGray4))
        }
    }

    private var socialSignInSection: some View {
        VStack(spacing: 12) {
            // Apple Sign In
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.email, .fullName]
            } onCompletion: { result in
                handleAppleSignIn(result: result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Google Sign In
            Button(action: handleGoogleSignIn) {
                HStack(spacing: 10) {
                    Image(systemName: "g.circle.fill")
                        .font(.title2)
                    Text("使用 Google 登入")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // LINE Login
            Button(action: handleLINELogin) {
                HStack(spacing: 10) {
                    Image(systemName: "message.fill")
                        .font(.title2)
                    Text("使用 LINE 登入")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private var signUpLink: some View {
        HStack(spacing: 4) {
            Text("還沒有帳號？")
                .foregroundStyle(.secondary)
            Button("立即註冊") {
                showSignUp = true
            }
            .foregroundStyle(.pink)
            .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    // MARK: - Google Sign In Handler

    private func handleGoogleSignIn() {
        print("[Google] Sign in tapped")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("[Google] ERROR: Cannot find rootViewController")
            authStore.error = "無法取得視窗"
            return
        }

        print("[Google] Presenting sign-in from \(type(of: rootVC))")
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error {
                if (error as NSError).code != GIDSignInError.canceled.rawValue {
                    authStore.error = error.localizedDescription
                }
                return
            }

            guard let idToken = result?.user.idToken?.tokenString else {
                authStore.error = "無法取得 Google ID Token"
                return
            }

            Task {
                await authStore.signInWithGoogle(idToken: idToken)
            }
        }
    }

    // MARK: - LINE Login Handler

    private func handleLINELogin() {
        print("[LINE] Login tapped")
        let channelID = AppConfig.lineChannelID
        let redirectURI = "\(AppConfig.apiBaseURL)/api/auth/line/callback"
        let state = UUID().uuidString

        let urlString = "https://access.line.me/oauth2/v2.1/authorize"
            + "?response_type=code"
            + "&client_id=\(channelID)"
            + "&redirect_uri=\(redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURI)"
            + "&state=\(state)"
            + "&scope=profile%20openid%20email"

        guard let url = URL(string: urlString) else {
            authStore.error = "LINE 登入 URL 無效"
            return
        }

        UIApplication.shared.open(url)
    }

    // MARK: - Apple Sign In Handler

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8),
                  let authCodeData = credential.authorizationCode,
                  let authorizationCode = String(data: authCodeData, encoding: .utf8)
            else {
                authStore.error = "無法取得 Apple 登入資訊"
                return
            }

            var fullName: String?
            if let givenName = credential.fullName?.givenName,
               let familyName = credential.fullName?.familyName {
                fullName = "\(familyName)\(givenName)"
            }

            Task {
                await authStore.signInWithApple(
                    identityToken: identityToken,
                    authorizationCode: authorizationCode,
                    fullName: fullName
                )
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                authStore.error = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        SignInView()
            .environment(AuthStore())
    }
}
