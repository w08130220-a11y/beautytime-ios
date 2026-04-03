import SwiftUI

struct PaymentStep: View {
    var store: BookingFlowStore

    @State private var showPaymentSheet = false
    @State private var paymentStatus: PaymentStatus?
    @State private var isCheckingResult = false

    var body: some View {
        VStack(spacing: 24) {
            if let status = paymentStatus {
                paymentResultView(status)
            } else {
                pendingPaymentView
            }
        }
    }

    // MARK: - Pending Payment

    private var pendingPaymentView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 4) {
                Text("付款")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("請支付訂金以完成預約")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Amount
            VStack(spacing: 4) {
                Text("應付金額")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Formatters.formatPrice(store.depositAmount))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            Button {
                Task {
                    await store.createPayment()
                    if store.paymentHTML != nil {
                        showPaymentSheet = true
                    }
                }
            } label: {
                HStack {
                    if store.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("前往付款")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.isLoading)
        }
        .sheet(isPresented: $showPaymentSheet) {
            if let html = store.paymentHTML {
                PaymentWebViewSheet(html: html) { _ in
                    showPaymentSheet = false
                    Task {
                        await checkResult()
                    }
                }
            }
        }
    }

    // MARK: - Payment Result

    private func paymentResultView(_ status: PaymentStatus) -> some View {
        VStack(spacing: 20) {
            switch status {
            case .paid:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                VStack(spacing: 4) {
                    Text("付款成功")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("您的預約已確認")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let booking = store.createdBooking {
                    VStack(spacing: 8) {
                        summaryRow(label: "預約編號", value: String(booking.id.prefix(8)))
                        summaryRow(label: "服務", value: store.selectedService?.name ?? "-")
                        summaryRow(label: "日期", value: store.selectedDate ?? "-")
                        summaryRow(label: "時間", value: store.selectedTime ?? "-")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }

                NavigationLink {
                    // Navigate to booking detail
                    if let booking = store.createdBooking {
                        Text("預約詳情：\(booking.id)")
                            .navigationTitle("預約詳情")
                    }
                } label: {
                    Text("查看預約")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)

            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.red)

                VStack(spacing: 4) {
                    Text("付款失敗")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("請重新嘗試付款")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    paymentStatus = nil
                } label: {
                    Text("重新付款")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)

            default:
                if isCheckingResult {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)
                    Text("確認付款結果中...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("付款狀態：處理中")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Check Result

    private func checkResult() async {
        isCheckingResult = true
        if let result = await store.checkPaymentResult() {
            paymentStatus = result.status
        } else {
            paymentStatus = .failed
        }
        isCheckingResult = false
    }
}

#Preview {
    let store = BookingFlowStore()
    ScrollView {
        PaymentStep(store: store)
            .padding()
    }
}
