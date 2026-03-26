import SwiftUI

struct UnpaidOrdersView: View {
    @State private var bookings: [Booking] = []
    @State private var isLoading = false
    @State private var error: String?

    private let api = APIClient.shared

    var unpaidBookings: [Booking] {
        bookings.filter { $0.depositPaid != true && $0.status == .pending }
    }

    var body: some View {
        Group {
            if isLoading && bookings.isEmpty {
                LoadingView()
            } else if unpaidBookings.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "沒有未付款訂單",
                    message: "所有訂單皆已付款完成"
                )
            } else {
                List(unpaidBookings) { booking in
                    UnpaidBookingRow(booking: booking)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("未付款訂單")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadBookings() }
        .refreshable { await loadBookings() }
    }

    private func loadBookings() async {
        isLoading = true
        do {
            bookings = try await api.get(path: APIEndpoints.Bookings.my)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Unpaid Booking Row

private struct UnpaidBookingRow: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Service & Provider
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.service?.name ?? "服務")
                        .font(.headline)

                    if let providerName = booking.provider?.name {
                        Label(providerName, systemImage: "storefront")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(PaymentStatus.pending.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(PaymentStatus.pending.color.opacity(0.15))
                    .foregroundStyle(PaymentStatus.pending.color)
                    .clipShape(Capsule())
            }

            // Date & Time
            if let date = booking.date, let time = booking.time {
                Label("\(Formatters.formatDate(date)) \(time)", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Price & Pay Button
            HStack {
                if let deposit = booking.depositAmount {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("訂金")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(Formatters.formatPrice(deposit))
                            .font(.subheadline.weight(.semibold))
                    }
                } else if let total = booking.totalPrice {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("總額")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(Formatters.formatPrice(total))
                            .font(.subheadline.weight(.semibold))
                    }
                }

                Spacer()

                NavigationLink {
                    PaymentFlowView(booking: booking)
                } label: {
                    Text("前往付款")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Payment Flow

struct PaymentFlowView: View {
    let booking: Booking

    @State private var paymentHTML: String?
    @State private var isLoading = false
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    private let api = APIClient.shared

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "建立付款中...")
            } else if let html = paymentHTML {
                ECPayWebView(html: html) { result in
                    dismiss()
                }
            } else if let error {
                ErrorView(message: error) {
                    Task { await createPayment() }
                }
            } else {
                Color.clear.onAppear {
                    Task { await createPayment() }
                }
            }
        }
        .navigationTitle("付款")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func createPayment() async {
        isLoading = true
        error = nil
        do {
            let response: PaymentResponse = try await api.post(
                path: APIEndpoints.Payments.create,
                body: ["bookingId": booking.id]
            )
            paymentHTML = response.html
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        UnpaidOrdersView()
    }
}
