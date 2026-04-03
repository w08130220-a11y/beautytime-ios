import SwiftUI

struct PlansTab: View {
    let providerId: String
    @State private var plans: [VoucherPlan] = []
    @State private var isLoading = false
    @State private var showPurchase = false

    private let api = APIClient.shared

    var body: some View {
        Group {
            if isLoading && plans.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, BTSpacing.xxl)
            } else if plans.isEmpty {
                VStack(spacing: BTSpacing.md) {
                    Image(systemName: "ticket")
                        .font(.largeTitle)
                        .foregroundStyle(BTColor.textTertiary)
                    Text("尚無方案")
                        .font(.subheadline)
                        .foregroundStyle(BTColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, BTSpacing.xxl)
            } else {
                LazyVStack(spacing: BTSpacing.md) {
                    ForEach(plans.filter { $0.isActive == true }) { plan in
                        PlanCard(plan: plan) {
                            showPurchase = true
                        }
                    }
                }
                .padding(.horizontal, BTSpacing.lg)
            }
        }
        .sheet(isPresented: $showPurchase) {
            NavigationStack {
                VoucherPurchaseView(providerId: providerId)
            }
            .presentationDetents([.large])
        }
        .task {
            await loadPlans()
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
            // Silently handle; empty state shown
        }
        isLoading = false
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let plan: VoucherPlan
    let onPurchase: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BTSpacing.md) {
            // Header: name + type badge
            HStack {
                Text(plan.name)
                    .font(.headline)
                    .foregroundStyle(BTColor.textPrimary)

                Spacer()

                if let type = plan.type {
                    BTBadge(text: type.displayName, color: type.color)
                }
            }

            // Description
            if let desc = plan.description, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(BTColor.textSecondary)
                    .lineLimit(2)
            }

            // Details row
            HStack(spacing: BTSpacing.lg) {
                if let validDays = plan.validDays {
                    Label("\(validDays) 天有效", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(BTColor.textSecondary)
                }

                if let sessions = plan.sessionsTotal, sessions > 0 {
                    Label("\(sessions) 次", systemImage: "number")
                        .font(.caption)
                        .foregroundStyle(BTColor.textSecondary)
                }

                Spacer()
            }

            Divider()

            // Price + buy button
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    if let original = plan.originalPrice,
                       let selling = plan.sellingPrice,
                       original != selling {
                        Text(Formatters.formatPrice(original))
                            .font(.caption)
                            .strikethrough()
                            .foregroundStyle(BTColor.textTertiary)
                    }
                    if let selling = plan.sellingPrice {
                        Text(Formatters.formatPrice(selling))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(BTColor.primary)
                    }
                }

                Spacer()

                Button(action: onPurchase) {
                    Text("購買")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, BTSpacing.xl)
                        .padding(.vertical, BTSpacing.sm)
                        .background(BTColor.primary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(BTSpacing.lg)
        .btCard()
    }
}

#Preview {
    PlansTab(providerId: "1")
}
