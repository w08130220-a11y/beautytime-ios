import SwiftUI

struct MarketingView: View {
    @Environment(ManageStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: BTSpacing.lg) {
                if store.marketingTemplates.isEmpty && !store.isLoading {
                    ContentUnavailableView(
                        "尚無行銷範本",
                        systemImage: "megaphone",
                        description: Text("行銷工具即將推出")
                    )
                } else {
                    ForEach(store.marketingTemplates) { template in
                        MarketingTemplateCard(template: template)
                    }
                }
            }
            .padding(BTSpacing.lg)
        }
        .btPageBackground()
        .navigationTitle("行銷工具")
        .task {
            await store.loadMarketingTemplates()
        }
        .refreshable {
            await store.loadMarketingTemplates()
        }
    }
}

// MARK: - Marketing Template Card

private struct MarketingTemplateCard: View {
    let template: MarketingTemplate

    var body: some View {
        HStack(spacing: BTSpacing.md) {
            Image(systemName: templateIcon)
                .font(.title3)
                .foregroundStyle(BTColor.primary)
                .frame(width: 40, height: 40)
                .background(BTColor.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))

            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                Text(template.name ?? "未命名範本")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(BTColor.textPrimary)

                if let type = template.type {
                    Text(type)
                        .font(.caption)
                        .foregroundStyle(BTColor.textSecondary)
                }
            }

            Spacer()

            if let isActive = template.isActive {
                BTBadge(
                    text: isActive ? "啟用中" : "未啟用",
                    color: isActive ? BTColor.success : BTColor.textTertiary
                )
            }
        }
        .padding(BTSpacing.lg)
        .btCard()
    }

    private var templateIcon: String {
        switch template.type {
        case "sms": return "message.fill"
        case "email": return "envelope.fill"
        case "push": return "bell.fill"
        default: return "megaphone.fill"
        }
    }
}

#Preview {
    NavigationStack {
        MarketingView()
            .environment(ManageStore())
    }
}
