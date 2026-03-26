import SwiftUI

struct PaymentMethodsView: View {
    private let paymentMethods: [(icon: String, name: String, description: String)] = [
        ("creditcard.fill", "信用卡", "Visa / MasterCard / JCB"),
        ("building.columns.fill", "ATM 轉帳", "透過網路銀行或 ATM 付款"),
        ("barcode", "超商代碼", "至 7-11、全家、萊爾富、OK 繳費"),
        ("apple.logo", "Apple Pay", "使用 Apple Pay 快速付款"),
        ("line.3.horizontal.circle.fill", "LINE Pay", "使用 LINE Pay 行動支付"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: BTSpacing.md) {
                // Info Banner
                HStack(spacing: BTSpacing.md) {
                    Image(systemName: "shield.checkered")
                        .font(.title2)
                        .foregroundStyle(BTColor.success)

                    VStack(alignment: .leading, spacing: BTSpacing.xs) {
                        Text("安全付款")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BTColor.textPrimary)
                        Text("所有付款均透過綠界科技(ECPay)安全處理，我們不會儲存您的付款資訊。")
                            .font(.caption)
                            .foregroundStyle(BTColor.textSecondary)
                            .lineSpacing(2)
                    }
                }
                .padding(BTSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BTColor.success.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))

                // Payment Methods List
                VStack(spacing: 0) {
                    ForEach(Array(paymentMethods.enumerated()), id: \.offset) { index, method in
                        HStack(spacing: BTSpacing.lg) {
                            Image(systemName: method.icon)
                                .font(.title3)
                                .foregroundStyle(BTColor.primary)
                                .frame(width: 40, height: 40)
                                .background(BTColor.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))

                            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                                Text(method.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(BTColor.textPrimary)
                                Text(method.description)
                                    .font(.caption)
                                    .foregroundStyle(BTColor.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .font(.body)
                                .foregroundStyle(BTColor.success)
                        }
                        .padding(.vertical, BTSpacing.md)
                        .padding(.horizontal, BTSpacing.lg)

                        if index < paymentMethods.count - 1 {
                            Divider().padding(.leading, 72)
                        }
                    }
                }
                .btCard()
            }
            .padding(BTSpacing.lg)
        }
        .background(BTColor.background)
        .navigationTitle("付款方式")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PaymentMethodsView()
    }
}
