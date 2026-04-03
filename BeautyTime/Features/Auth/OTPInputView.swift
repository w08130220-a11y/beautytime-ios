import SwiftUI

struct OTPInputView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(\.dismiss) private var dismiss

    let email: String

    @State private var otpDigits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    @State private var resendCountdown: Int = 60
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 20)

            // Header
            VStack(spacing: 12) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.pink)

                Text("輸入驗證碼")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("驗證碼已發送至\n\(email)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // OTP Input Boxes
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    TextField("", text: $otpDigits[index])
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .multilineTextAlignment(.center)
                        .font(.title.monospaced().bold())
                        .frame(width: 48, height: 56)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    focusedIndex == index ? Color.pink : Color(.systemGray4),
                                    lineWidth: focusedIndex == index ? 2 : 1
                                )
                        )
                        .focused($focusedIndex, equals: index)
                        .onChange(of: otpDigits[index]) { oldValue, newValue in
                            handleDigitChange(at: index, oldValue: oldValue, newValue: newValue)
                        }
                }
            }

            // Error
            if let error = authStore.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // Loading
            if authStore.isLoading {
                ProgressView("驗證中...")
            }

            // Resend
            Group {
                if resendCountdown > 0 {
                    Text("重新發送驗證碼 (\(resendCountdown)秒)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        Task { await resendOTP() }
                    } label: {
                        Text("重新發送")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.pink)
                    }
                    .disabled(authStore.isLoading)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .navigationTitle("驗證碼")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    cleanup()
                    dismiss()
                }
            }
        }
        .onAppear {
            startTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedIndex = 0
            }
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: authStore.isAuthenticated) { _, authenticated in
            if authenticated {
                cleanup()
                dismiss()
            }
        }
    }

    // MARK: - Digit Handling

    private func handleDigitChange(at index: Int, oldValue: String, newValue: String) {
        // Handle paste (multiple characters)
        if newValue.count > 1 {
            let digits = newValue.filter(\.isNumber)
            if digits.count >= 2 {
                // Distribute pasted digits across boxes
                let digitArray = Array(digits.prefix(6))
                for i in 0..<min(digitArray.count, 6) {
                    otpDigits[i] = String(digitArray[i])
                }
                if digitArray.count >= 6 {
                    focusedIndex = nil
                    submitOTP()
                } else {
                    focusedIndex = min(digitArray.count, 5)
                }
                return
            }
            // Single char with extra, keep only last digit
            otpDigits[index] = String(newValue.filter(\.isNumber).suffix(1))
        }

        // Filter non-digits
        let filtered = newValue.filter(\.isNumber)
        if filtered != newValue {
            otpDigits[index] = filtered
            return
        }

        // Move to next field
        if !filtered.isEmpty && index < 5 {
            focusedIndex = index + 1
        }

        // Check if all 6 digits are filled
        let fullCode = otpDigits.joined()
        if fullCode.count == 6 {
            focusedIndex = nil
            submitOTP()
        }
    }

    // MARK: - Actions

    private func submitOTP() {
        let code = otpDigits.joined()
        guard code.count == 6 else { return }
        Task {
            await authStore.verifyOTP(email: email, otp: code)
            // If verification failed, refocus
            if authStore.error != nil {
                otpDigits = Array(repeating: "", count: 6)
                focusedIndex = 0
            }
        }
    }

    private func resendOTP() async {
        authStore.error = nil
        otpDigits = Array(repeating: "", count: 6)
        focusedIndex = 0
        await authStore.sendOTP(email: email)
        resendCountdown = 60
        startTimer()
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        resendCountdown = 60
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if resendCountdown > 0 {
                    resendCountdown -= 1
                } else {
                    stopTimer()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func cleanup() {
        stopTimer()
        authStore.otpSent = false
        authStore.error = nil
    }
}
