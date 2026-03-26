import SwiftUI

struct VoucherPurchaseView: View {
    let providerId: String

    @Environment(\.dismiss) private var dismiss

    @State private var plans: [VoucherPlan] = []
    @State private var selectedPlan: VoucherPlan?
    @State private var isLoading = false
    @State private var isPurchasing = false
    @State private var error: String?
    @State private var showPaymentSheet = false
    @State private var paymentHTML: String?
    @State private var showSuccess = false

    private let api = APIClient.shared

    var body: some View {
        Group {
            if isLoading && plans.isEmpty {
                ProgressView("載入中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if plans.filter({ $0.isActive == true }).isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "ticket.slash")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("沒有可用的票券方案")
                        .font(.headline)
                    Text("此服務商尚未設定票券方案")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(plans.filter { $0.isActive == true }) { plan in
                            VoucherPlanCard(
                                plan: plan,
                                isSelected: selectedPlan?.id == plan.id
                            ) {
                                selectedPlan = plan
                            }
                        }
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    if let plan = selectedPlan {
                        Button {
                            Task { await purchaseVoucher() }
                        } label: {
                            HStack {
                                if isPurchasing { ProgressView().tint(.white) }
                                Text("購買 \(Formatters.formatPrice(plan.sellingPrice ?? 0))")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isPurchasing)
                        .padding()
                        .background(.ultraThinMaterial)
                    }
                }
            }
        }
        .navigationTitle("購買票券")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPlans()
        }
        .alert("錯誤", isPresented: Binding(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("確定") { error = nil }
        } message: {
            Text(error ?? "")
        }
        .alert("購買成功", isPresented: $showSuccess) {
            Button("確定") { dismiss() }
        } message: {
            Text("票券已加入您的帳戶，可在「我的票券」中查看。")
        }
        .sheet(isPresented: $showPaymentSheet) {
            if let html = paymentHTML {
                PaymentWebViewSheet(html: html) { _ in
                    showPaymentSheet = false
                    showSuccess = true
                }
            }
        }
    }

    private func loadPlans() async {
        isLoading = true
        do {
            plans = try await api.get(
                path: APIEndpoints.Vouchers.plans,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func purchaseVoucher() async {
        guard let plan = selectedPlan else { return }
        isPurchasing = true

        do {
            // Purchase returns { voucher: {...}, payment: {...} }
            let response: VoucherPurchaseResponse = try await api.post(
                path: APIEndpoints.Vouchers.purchase(plan.id)
            )
            showSuccess = true
        } catch {
            self.error = "購買失敗：\(error.localizedDescription)"
        }

        isPurchasing = false
    }
}

// MARK: - Voucher Plan Card

private struct VoucherPlanCard: View {
    let plan: VoucherPlan
    let isSelected: Bool
    let onTap: () -> Void

    private var sellingPriceValue: Int { Int(plan.sellingPrice ?? 0) }
    private var originalPriceValue: Int { Int(plan.originalPrice ?? 0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.headline)

                    if let type = plan.type {
                        Text(type.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(type.color.opacity(0.15))
                            .foregroundStyle(type.color)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if originalPriceValue != sellingPriceValue {
                        Text(Formatters.formatPrice(Double(originalPriceValue)))
                            .font(.caption)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                    }
                    Text(Formatters.formatPrice(Double(sellingPriceValue)))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.pink)
                }
            }

            if let desc = plan.description {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                if let sessions = plan.sessionsTotal {
                    Label("\(sessions) 次", systemImage: "number.circle")
                        .font(.caption)
                }
                if let days = plan.validDays {
                    Label("有效 \(days) 天", systemImage: "calendar")
                        .font(.caption)
                }
                if let maxSales = plan.maxSales {
                    Label("限量 \(maxSales) 份", systemImage: "bag")
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.pink : Color(.systemGray5), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .onTapGesture { onTap() }
    }
}
