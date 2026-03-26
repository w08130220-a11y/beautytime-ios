import SwiftUI

struct SignUpView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var showOTP = false

    private var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty && isEmailValid
    }

    private var isEmailValid: Bool {
        let pattern = /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/
        return email.wholeMatch(of: pattern) != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // MARK: - Header
                VStack(spacing: 8) {
                    Text("建立帳號")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("歡迎加入 BeautyTime")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Form Fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("姓名")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("請輸入您的姓名", text: $fullName)
                            .textContentType(.name)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("電子信箱")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("請輸入電子信箱", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if !email.isEmpty && !isEmailValid {
                            Text("請輸入有效的電子信箱")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("手機號碼")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("(選填)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        TextField("例：0912345678", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // MARK: - Register Button
                Button {
                    Task {
                        await register()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if authStore.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("註冊")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid && !authStore.isLoading ? Color.pink : Color.pink.opacity(0.4))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isFormValid || authStore.isLoading)

                // MARK: - Sign In Link
                HStack(spacing: 4) {
                    Text("已有帳號？")
                        .foregroundStyle(.secondary)
                    Button("登入") {
                        dismiss()
                    }
                    .foregroundStyle(.pink)
                    .fontWeight(.semibold)
                }
                .font(.subheadline)

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("註冊")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
        }
        .sheet(isPresented: $showOTP) {
            NavigationStack {
                OTPInputView(email: email)
            }
            .presentationDetents([.medium, .large])
        }
        .onChange(of: authStore.otpSent) { _, sent in
            if sent {
                showOTP = true
            }
        }
        .alert("錯誤", isPresented: .constant(authStore.error != nil)) {
            Button("確定") { authStore.error = nil }
        } message: {
            if let error = authStore.error {
                Text(error)
            }
        }
    }

    // MARK: - Actions

    private func register() async {
        await authStore.sendOTP(
            email: email,
            type: "signup",
            fullName: fullName.isEmpty ? nil : fullName
        )
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environment(AuthStore())
    }
}
