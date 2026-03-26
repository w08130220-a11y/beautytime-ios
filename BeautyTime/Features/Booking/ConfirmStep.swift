import SwiftUI

struct ConfirmStep: View {
    @Bindable var store: BookingFlowStore

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Summary Card
            summaryCard

            // MARK: - Note
            noteSection

            // MARK: - Coupon
            couponSection

            // MARK: - Price Breakdown
            priceBreakdown

            // MARK: - Cancellation Policy
            policyNote
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("預約摘要")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                summaryRow(icon: "scissors", label: "服務", value: store.selectedService?.name ?? "-")

                summaryRow(
                    icon: "person.fill",
                    label: "設計師",
                    value: store.selectedStaff?.name ?? "不指定"
                )

                summaryRow(icon: "calendar", label: "日期", value: store.selectedDate ?? "-")

                summaryRow(icon: "clock", label: "時間", value: store.selectedTime ?? "-")

                if let duration = store.selectedService?.duration {
                    summaryRow(icon: "hourglass", label: "時長", value: "\(duration) 分鐘")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("備註（選填）")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            TextField("例如：特殊需求、過敏資訊等", text: $store.note, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Coupon Section

    private var couponSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("優惠碼")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField("輸入優惠碼", text: Binding(
                    get: { store.couponCode ?? "" },
                    set: { store.couponCode = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.characters)

                Button {
                    Task { await store.verifyCoupon() }
                } label: {
                    Text("驗證")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.couponCode == nil || store.couponCode?.isEmpty == true || store.isLoading)
            }

            if let coupon = store.verifiedCoupon {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(coupon.description ?? "優惠碼已套用")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    // MARK: - Price Breakdown

    private var priceBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("費用明細")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                priceRow(label: "小計", amount: store.totalPrice)

                if store.discountAmount > 0 {
                    priceRow(label: "折扣", amount: -store.discountAmount, highlight: true)
                }

                if store.depositAmount < store.finalPrice {
                    priceRow(label: "訂金", amount: store.depositAmount)
                }

                Divider()

                HStack {
                    Text("合計")
                        .font(.headline)
                    Spacer()
                    Text(Formatters.formatPrice(store.finalPrice))
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private func priceRow(label: String, amount: Double, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(Formatters.formatPrice(amount))
                .font(.subheadline)
                .foregroundStyle(highlight ? .green : .primary)
        }
    }

    // MARK: - Policy Note

    private var policyNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("預約成立後如需取消，請依照店家取消政策辦理。未於規定時間內取消可能無法退還訂金。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    let store = BookingFlowStore()
    ScrollView {
        ConfirmStep(store: store)
            .padding()
    }
}
