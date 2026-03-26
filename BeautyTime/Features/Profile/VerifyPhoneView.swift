import SwiftUI

struct VerifyPhoneView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(\.dismiss) private var dismiss

    @State private var phoneNumber = ""
    @State private var otpCode = ""
    @State private var otpSent = false
    @State private var isLoading = false
    @State private var error: String?
    @State private var cooldown = 0
    @State private var showSuccess = false

    private let api = APIClient.shared

    var body: some View {
        ScrollView {
            VStack(spacing: BTSpacing.xl) {
                // Header Icon
                Image(systemName: "phone.badge.checkmark")
                    .font(.system(size: 56))
                    .foregroundStyle(BTColor.primary)
                    .padding(.top, BTSpacing.xxl)

                Text("驗證手機號碼")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(BTColor.textPrimary)

                Text("輸入您的手機號碼，我們將發送驗證碼進行驗證。")
                    .font(.body)
                    .foregroundStyle(BTColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BTSpacing.xl)

                // Phone Number Input
                VStack(alignment: .leading, spacing: BTSpacing.sm) {
                    Text("手機號碼")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BTColor.textSecondary)

                    HStack(spacing: BTSpacing.sm) {
                        Text("+886")
                            .font(.body.weight(.medium))
                            .foregroundStyle(BTColor.textPrimary)
                            .padding(.horizontal, BTSpacing.md)
                            .padding(.vertical, BTSpacing.md)
                            .background(BTColor.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))

                        TextField("912345678", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .padding(BTSpacing.md)
                            .background(BTColor.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))
                            .overlay(
                                RoundedRectangle(cornerRadius: BTRadius.sm)
                                    .stroke(BTColor.border, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, BTSpacing.lg)

                // Send OTP Button
                if !otpSent {
                    Button {
                        Task { await sendOTP() }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .btPrimaryButton()
                        } else {
                            Text("發送驗證碼")
                                .btPrimaryButton(isDisabled: phoneNumber.count < 9)
                        }
                    }
                    .disabled(phoneNumber.count < 9 || isLoading)
                    .padding(.horizontal, BTSpacing.lg)
                }

                // OTP Input (shown after sending)
                if otpSent {
                    VStack(alignment: .leading, spacing: BTSpacing.sm) {
                        Text("驗證碼")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(BTColor.textSecondary)

                        TextField("請輸入 6 位驗證碼", text: $otpCode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .padding(BTSpacing.lg)
                            .background(BTColor.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: BTRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: BTRadius.md)
                                    .stroke(BTColor.border, lineWidth: 1)
                            )

                        // Resend button
                        HStack {
                            Spacer()
                            if cooldown > 0 {
                                Text("重新發送 (\(cooldown)s)")
                                    .font(.caption)
                                    .foregroundStyle(BTColor.textTertiary)
                            } else {
                                Button("重新發送驗證碼") {
                                    Task { await sendOTP() }
                                }
                                .font(.caption.weight(.medium))
                                .foregroundStyle(BTColor.primary)
                            }
                        }
                    }
                    .padding(.horizontal, BTSpacing.lg)

                    // Verify Button
                    Button {
                        Task { await verifyOTP() }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .btPrimaryButton()
                        } else {
                            Text("驗證")
                                .btPrimaryButton(isDisabled: otpCode.count < 6)
                        }
                    }
                    .disabled(otpCode.count < 6 || isLoading)
                    .padding(.horizontal, BTSpacing.lg)
                }

                // Error
                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(BTColor.error)
                        .padding(.horizontal, BTSpacing.lg)
                }

                Spacer()
            }
        }
        .background(BTColor.background)
        .navigationTitle("驗證手機")
        .navigationBarTitleDisplayMode(.inline)
        .alert("驗證成功", isPresented: $showSuccess) {
            Button("確定") { dismiss() }
        } message: {
            Text("您的手機號碼已成功驗證。")
        }
        .onAppear {
            // Pre-fill phone if available
            if let phone = authStore.currentUser?.phone {
                phoneNumber = phone.replacingOccurrences(of: "+886", with: "")
            }
        }
    }

    // MARK: - Send OTP

    private func sendOTP() async {
        isLoading = true
        error = nil
        do {
            let fullPhone = "+886\(phoneNumber)"
            let _: OTPResponse = try await api.post(
                path: "/api/auth/phone/send-otp",
                body: JSONBody(["phone": fullPhone])
            )
            otpSent = true
            startCooldown()
        } catch {
            self.error = "發送驗證碼失敗，請稍後再試。"
        }
        isLoading = false
    }

    // MARK: - Verify OTP

    private func verifyOTP() async {
        isLoading = true
        error = nil
        do {
            let fullPhone = "+886\(phoneNumber)"
            let _: OTPResponse = try await api.post(
                path: "/api/auth/phone/verify-otp",
                body: JSONBody(["phone": fullPhone, "code": otpCode])
            )
            await authStore.fetchCurrentUser()
            showSuccess = true
        } catch {
            self.error = "驗證碼錯誤或已過期，請重新嘗試。"
        }
        isLoading = false
    }

    // MARK: - Cooldown Timer

    private func startCooldown() {
        cooldown = 60
        Task {
            while cooldown > 0 {
                try? await Task.sleep(for: .seconds(1))
                cooldown -= 1
            }
        }
    }
}

#Preview {
    NavigationStack {
        VerifyPhoneView()
            .environment(AuthStore())
    }
}
