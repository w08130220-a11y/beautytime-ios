import SwiftUI

struct MyCouponsView: View {
    @State private var couponCode = ""
    @State private var verifiedCoupon: Coupon?
    @State private var isVerifying = false
    @State private var error: String?
    @State private var savedCoupons: [Coupon] = []

    private let api = APIClient.shared

    var body: some View {
        List {
            Section(header: Text("輸入優惠碼")) {
                HStack {
                    TextField("輸入優惠碼", text: $couponCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    Button {
                        Task { await verifyCoupon() }
                    } label: {
                        if isVerifying {
                            ProgressView()
                        } else {
                            Text("驗證")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(couponCode.trimmingCharacters(in: .whitespaces).isEmpty || isVerifying)
                }
            }

            if let error {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            if let coupon = verifiedCoupon {
                Section(header: Text("優惠券詳情")) {
                    CouponCard(coupon: coupon)
                }
            }

            if !savedCoupons.isEmpty {
                Section(header: Text("我的優惠券")) {
                    ForEach(savedCoupons) { coupon in
                        CouponCard(coupon: coupon)
                    }
                }
            } else if verifiedCoupon == nil {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "tag.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("沒有優惠券")
                            .font(.headline)
                        Text("輸入優惠碼來新增優惠券")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("我的優惠券")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func verifyCoupon() async {
        isVerifying = true
        error = nil
        verifiedCoupon = nil

        do {
            let response: CouponVerifyResponse = try await api.post(
                path: APIEndpoints.Coupons.verify,
                body: ["code": couponCode.trimmingCharacters(in: .whitespaces)]
            )
            if response.valid, let coupon = response.coupon {
                verifiedCoupon = coupon
                if !savedCoupons.contains(where: { $0.id == coupon.id }) {
                    savedCoupons.insert(coupon, at: 0)
                }
            } else {
                error = response.message ?? "優惠碼無效"
            }
        } catch {
            self.error = "驗證失敗：\(error.localizedDescription)"
        }

        isVerifying = false
    }
}

// MARK: - Coupon Card

private struct CouponCard: View {
    let coupon: Coupon

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(coupon.code ?? "---")
                    .font(.headline)
                    .monospaced()

                Spacer()

                Text(discountText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.pink)
                    .clipShape(Capsule())
            }

            if let desc = coupon.description {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                if let minAmount = coupon.minOrderAmount, minAmount > 0 {
                    Text("最低消費 \(Formatters.formatPrice(minAmount))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let validUntil = coupon.validUntil {
                    Text("有效至 \(Formatters.displayDate(validUntil))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if coupon.isActive == false {
                Text("已失效")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private var discountText: String {
        guard let type = coupon.discountType, let value = coupon.discountValue else {
            return "優惠"
        }
        switch type {
        case .percentage:
            return "\(Int(value))% OFF"
        case .fixed:
            return "折 \(Formatters.formatPrice(value))"
        }
    }
}
