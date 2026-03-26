import SwiftUI

struct VoucherRedeemView: View {
    @Environment(VoucherManageStore.self) private var voucherStore

    @State private var tokenInput = ""
    @State private var voucherInfo: VoucherVerifyResponse?
    @State private var isVerifying = false
    @State private var isRedeeming = false
    @State private var error: String?
    @State private var showSuccess = false
    @State private var showScanner = false

    @State private var selectedServiceId = ""
    @State private var selectedStaffId = ""

    private let api = APIClient.shared

    var body: some View {
        Form {
            Section(header: Text("掃描或輸入兌換碼")) {
                HStack {
                    TextField("輸入兌換碼", text: $tokenInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button {
                        showScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.title2)
                    }
                }

                Button {
                    Task { await verifyToken(tokenInput) }
                } label: {
                    HStack {
                        if isVerifying { ProgressView() }
                        Text("驗證").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(tokenInput.trimmingCharacters(in: .whitespaces).isEmpty || isVerifying)
            }

            if let error {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            if let info = voucherInfo, let voucher = info.voucher {
                Section(header: Text("票券資訊")) {
                    if let plan = info.plan {
                        LabeledContent("票券名稱", value: plan.name)
                        if let type = plan.type {
                            LabeledContent("類型", value: type.displayName)
                        }
                    }
                    if let remaining = voucher.sessionsRemaining {
                        LabeledContent("剩餘次數", value: "\(remaining)")
                    }
                    if let balance = voucher.balanceRemaining {
                        LabeledContent("剩餘金額", value: Formatters.formatPrice(balance))
                    }
                    if let status = voucher.status {
                        LabeledContent("狀態", value: status.displayName)
                    }
                }

                Section(header: Text("兌換資訊（選填）")) {
                    TextField("服務 ID", text: $selectedServiceId)
                    TextField("員工 ID", text: $selectedStaffId)
                }

                Section {
                    Button {
                        Task { await redeemVoucher() }
                    } label: {
                        HStack {
                            Spacer()
                            if isRedeeming { ProgressView().tint(.white) }
                            Text("確認兌換").fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(isRedeeming)
                    .listRowBackground(Color.pink)
                    .foregroundStyle(.white)
                }
            }
        }
        .navigationTitle("票券兌換")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showScanner) {
            QRScannerView { code in
                showScanner = false
                tokenInput = code
                Task { await verifyToken(code) }
            }
        }
        .alert("兌換成功", isPresented: $showSuccess) {
            Button("確定") {
                tokenInput = ""
                voucherInfo = nil
            }
        } message: {
            Text("票券已成功兌換！")
        }
    }

    private func verifyToken(_ token: String) async {
        let trimmed = token.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isVerifying = true
        error = nil
        voucherInfo = nil

        do {
            let response: VoucherVerifyResponse = try await api.post(
                path: APIEndpoints.Vouchers.verifyToken,
                body: ["token": trimmed]
            )
            voucherInfo = response
            if response.voucher == nil {
                error = "兌換碼無效或已過期"
            }
        } catch {
            self.error = "驗證失敗：\(error.localizedDescription)"
        }

        isVerifying = false
    }

    private func redeemVoucher() async {
        let token = tokenInput.trimmingCharacters(in: .whitespaces)
        guard !token.isEmpty else { return }

        isRedeeming = true
        error = nil

        do {
            var body: [String: Any] = ["token": token]
            if !selectedServiceId.isEmpty { body["serviceId"] = selectedServiceId }
            if !selectedStaffId.isEmpty { body["staffId"] = selectedStaffId }

            let _: CustomerVoucher = try await api.post(
                path: APIEndpoints.Vouchers.redeem,
                body: JSONBody(body)
            )
            showSuccess = true
        } catch {
            self.error = "兌換失敗：\(error.localizedDescription)"
        }

        isRedeeming = false
    }
}

// QRScannerView is defined in Components/QRCodeView.swift
