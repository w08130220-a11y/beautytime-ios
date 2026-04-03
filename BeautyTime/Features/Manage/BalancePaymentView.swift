import SwiftUI

/// Merchant-side: collect balance payment after service is completed.
/// Two options: show QR for online payment, or mark as cash received.
struct BalancePaymentView: View {
    let booking: Booking
    @Environment(OrderManageStore.self) private var orderStore
    @State private var showQR = false
    @State private var markedCash = false
    @Environment(\.dismiss) private var dismiss

    private var balanceAmount: Double {
        booking.balanceAmount ?? ((booking.totalPrice ?? 0) - (booking.depositAmount ?? 0))
    }

    var body: some View {
        VStack(spacing: 24) {
            // Amount header
            VStack(spacing: 8) {
                Text("尾款金額")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(Formatters.formatPrice(balanceAmount))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.accent)
            }
            .padding(.top, 32)

            // Service info
            VStack(spacing: 6) {
                if let service = booking.service {
                    Text(service.name)
                        .font(.headline)
                }
                Text("\(booking.date ?? "") \(booking.time ?? "")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let customer = booking.customer {
                    Text(customer.fullName ?? "顧客")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            if markedCash {
                // Cash confirmed
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("已收現金")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .padding(.vertical, 32)
            } else {
                // Payment options
                VStack(spacing: 16) {
                    // Option 1: QR Code for online payment
                    Button {
                        showQR = true
                    } label: {
                        HStack {
                            Image(systemName: "qrcode")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("線上收款")
                                    .font(.headline)
                                Text("出示 QR Code 讓客人掃碼付款")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    // Option 2: Mark as cash
                    Button {
                        Task {
                            await orderStore.markBalancePaid(bookingId: booking.id, method: "cash")
                            markedCash = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "banknote")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("現金收款")
                                    .font(.headline)
                                Text("客人已付現金，標記為已收款")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("收尾款")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showQR) {
            NavigationStack {
                BalanceQRView(booking: booking, amount: balanceAmount)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("關閉") { showQR = false }
                        }
                    }
            }
        }
    }
}

/// Shows the balance payment QR Code for the consumer to scan.
/// Content: beautytime://pay/{bookingId}/{amount}
struct BalanceQRView: View {
    let booking: Booking
    let amount: Double

    var body: some View {
        VStack(spacing: 24) {
            Text("請客人掃碼付款")
                .font(.headline)

            Text(Formatters.formatPrice(amount))
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.accent)

            let qrContent = "beautytime://pay/\(booking.id)/\(Int(amount))"
            QRCodeView(content: qrContent)
                .frame(width: 200, height: 200)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.1), radius: 8)
                )

            Text("QR Code 有效期 10 分鐘")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("尾款 QR Code")
        .navigationBarTitleDisplayMode(.inline)
    }
}
