import SwiftUI

struct VoucherDetailView: View {
    let voucher: CustomerVoucher

    @State private var tokenResponse: VoucherTokenResponse?
    @State private var transactions: [VoucherTransaction] = []
    @State private var isLoadingToken = false
    @State private var isLoadingTransactions = false
    @State private var showCancelAlert = false
    @State private var isCancelling = false
    @State private var error: String?
    @State private var tokenCountdown: Int = 0
    @State private var countdownTimer: Timer?

    @Environment(\.dismiss) private var dismiss

    private let api = APIClient.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                planInfoSection
                providerSection
                usageSection
                expirySection
                qrCodeSection
                transactionSection
                cancelSection
            }
            .padding()
        }
        .navigationTitle("票券詳情")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadTransactions() }
        .alert("取消票券", isPresented: $showCancelAlert) {
            Button("確定取消", role: .destructive) {
                Task { await cancelVoucher() }
            }
            Button("返回", role: .cancel) {}
        } message: {
            Text("確定要取消這張票券嗎？取消後將無法使用，退款將依照規定處理。")
        }
        .onDisappear {
            countdownTimer?.invalidate()
        }
    }

    // MARK: - Plan Info

    private var planInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(voucher.plan?.name ?? "票券")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if let type = voucher.plan?.type {
                    Text(type.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
            }

            if let status = voucher.status {
                HStack(spacing: 6) {
                    Circle()
                        .fill(status.color)
                        .frame(width: 8, height: 8)
                    Text(status.displayName)
                        .font(.subheadline)
                        .foregroundStyle(status.color)
                }
            }

            if let description = voucher.plan?.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Provider

    private var providerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("商家", systemImage: "storefront")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(voucher.provider?.name ?? "—")
                    .font(.headline)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Usage Stats

    private var usageSection: some View {
        VStack(spacing: 8) {
            switch voucher.plan?.type {
            case .session:
                HStack {
                    Text("剩餘次數")
                    Spacer()
                    Text("\(voucher.sessionsRemaining ?? 0) 次")
                        .fontWeight(.semibold)
                }
                if let total = voucher.plan?.sessionsTotal {
                    HStack {
                        Text("總次數")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(total) 次")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    ProgressView(
                        value: Double(voucher.sessionsRemaining ?? 0),
                        total: Double(total)
                    )
                    .tint(.accentColor)
                }

            case .storedValue:
                HStack {
                    Text("剩餘餘額")
                    Spacer()
                    Text(Formatters.formatPrice(voucher.balanceRemaining ?? 0))
                        .fontWeight(.semibold)
                }
                if let original = voucher.purchasePrice {
                    HStack {
                        Text("購買金額")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Formatters.formatPrice(original))
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }

            case .package:
                if let remaining = voucher.packageRemaining, !remaining.isEmpty {
                    ForEach(remaining.sorted(by: { $0.key < $1.key }), id: \.key) { serviceName, count in
                        HStack {
                            Text(serviceName)
                            Spacer()
                            Text("剩餘 \(count) 次")
                                .fontWeight(.semibold)
                        }
                    }
                }

            case .none:
                EmptyView()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Expiry

    private var expirySection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("到期日", systemImage: "calendar.badge.clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let expiresAt = voucher.expiresAt {
                    Text(formatDate(expiresAt))
                        .font(.headline)
                    Text(daysRemainingText(expiresAt))
                        .font(.caption)
                        .foregroundStyle(isExpiringSoon(expiresAt) ? .orange : .secondary)
                } else {
                    Text("無期限")
                        .font(.headline)
                }
            }
            Spacer()
            if let purchasedAt = voucher.purchasedAt {
                VStack(alignment: .trailing, spacing: 4) {
                    Label("購買日", systemImage: "cart")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatDate(purchasedAt))
                        .font(.headline)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - QR Code

    private var qrCodeSection: some View {
        VStack(spacing: 12) {
            if let tokenResponse {
                Text("兌換 QR Code")
                    .font(.headline)

                QRCodeView(data: tokenResponse.token, size: 200)

                Text(tokenResponse.token)
                    .font(.caption)
                    .monospaced()
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                if tokenCountdown > 0 {
                    Label("有效時間剩餘 \(formatCountdown(tokenCountdown))", systemImage: "timer")
                        .font(.subheadline)
                        .foregroundStyle(tokenCountdown <= 30 ? .red : .orange)
                } else if self.tokenResponse != nil {
                    Label("兌換碼已過期", systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                Button("重新產生") {
                    Task { await generateToken() }
                }
                .buttonStyle(.bordered)
                .disabled(isLoadingToken)
            } else if voucher.status == .active {
                Button {
                    Task { await generateToken() }
                } label: {
                    HStack {
                        if isLoadingToken {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "qrcode")
                        }
                        Text("產生兌換碼")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoadingToken)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Transactions

    private var transactionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("使用記錄", systemImage: "list.bullet.rectangle")
                    .font(.headline)
                Spacer()
                if isLoadingTransactions {
                    ProgressView()
                }
            }

            if transactions.isEmpty && !isLoadingTransactions {
                Text("尚無使用記錄")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                ForEach(transactions) { transaction in
                    TransactionRow(transaction: transaction, voucherType: voucher.plan?.type)
                    if transaction.id != transactions.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Cancel

    @ViewBuilder
    private var cancelSection: some View {
        if voucher.status == .active {
            Button(role: .destructive) {
                showCancelAlert = true
            } label: {
                HStack {
                    if isCancelling {
                        ProgressView()
                            .tint(.red)
                    }
                    Text("取消票券")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isCancelling)
        }
    }

    // MARK: - Actions

    private func generateToken() async {
        isLoadingToken = true
        countdownTimer?.invalidate()
        do {
            let response: VoucherTokenResponse = try await api.post(
                path: APIEndpoints.Vouchers.generateToken(voucher.id)
            )
            tokenResponse = response
            startCountdown(expiresAt: response.expiresAt)
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingToken = false
    }

    private func loadTransactions() async {
        isLoadingTransactions = true
        do {
            transactions = try await api.get(
                path: APIEndpoints.Vouchers.transactions(voucher.id)
            )
        } catch {
            // Silently handle; transactions are supplementary
        }
        isLoadingTransactions = false
    }

    private func cancelVoucher() async {
        isCancelling = true
        do {
            let _: CustomerVoucher = try await api.patch(
                path: APIEndpoints.Vouchers.cancel(voucher.id)
            )
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isCancelling = false
    }

    // MARK: - Timer

    private func startCountdown(expiresAt: Date?) {
        guard let expiresAt else { return }
        let seconds = Int(expiresAt.timeIntervalSince(Date()))
        guard seconds > 0 else {
            tokenCountdown = 0
            return
        }
        tokenCountdown = seconds
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if tokenCountdown > 0 {
                tokenCountdown -= 1
            } else {
                countdownTimer?.invalidate()
            }
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        Formatters.slashDateFormatter.string(from: date)
    }

    private func daysRemainingText(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days < 0 {
            return "已過期"
        } else if days == 0 {
            return "今天到期"
        } else {
            return "剩餘 \(days) 天"
        }
    }

    private func isExpiringSoon(_ date: Date) -> Bool {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return days >= 0 && days <= 14
    }

    private func formatCountdown(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: VoucherTransaction
    let voucherType: VoucherType?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transactionTypeLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let createdAt = transaction.createdAt {
                    Text(Formatters.relativeDate(createdAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                usageLabel
                if let fee = transaction.upgradeFee, fee > 0 {
                    Text("加價 \(Formatters.formatPrice(fee))")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var transactionTypeLabel: String {
        switch transaction.type {
        case .redeem: return "兌換使用"
        case .upgrade: return "升級加價"
        case .refund: return "退款"
        case .extend: return "延期"
        case .freeze: return "凍結"
        case .unfreeze: return "解凍"
        case .none: return "—"
        }
    }

    @ViewBuilder
    private var usageLabel: some View {
        switch voucherType {
        case .session:
            if let sessions = transaction.sessionsUsed {
                Text("-\(sessions) 次")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(transaction.type == .refund ? .green : .primary)
            }
        case .storedValue:
            if let amount = transaction.amountUsed {
                Text(transaction.type == .refund ? "+\(Formatters.formatPrice(amount))" : "-\(Formatters.formatPrice(amount))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(transaction.type == .refund ? .green : .primary)
            }
        case .package:
            if let sessions = transaction.sessionsUsed {
                Text("-\(sessions) 次")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
        case .none:
            EmptyView()
        }
    }
}
