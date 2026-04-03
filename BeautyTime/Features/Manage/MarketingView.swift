import SwiftUI

struct MarketingView: View {
    @Environment(ManageStore.self) private var store
    @State private var editingTemplate: MarketingTemplate?
    @State private var editMessage = ""
    @State private var editEnabled = true

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
                        MarketingTemplateCard(template: template) {
                            editingTemplate = template
                            editMessage = template.displayMessage
                            editEnabled = template.isEnabled
                        }
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
        .sheet(item: $editingTemplate) { template in
            NavigationStack {
                MarketingTemplateEditSheet(
                    template: template,
                    message: $editMessage,
                    enabled: $editEnabled
                ) {
                    await store.updateMarketingTemplate(
                        id: template.id,
                        message: editMessage,
                        enabled: editEnabled
                    )
                    editingTemplate = nil
                }
            }
        }
    }
}

// MARK: - Edit Sheet

private struct MarketingTemplateEditSheet: View {
    let template: MarketingTemplate
    @Binding var message: String
    @Binding var enabled: Bool
    let onSave: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false

    var body: some View {
        Form {
            Section("範本類型") {
                HStack {
                    Text(template.typeName)
                    Spacer()
                    Toggle("啟用", isOn: $enabled)
                        .labelsHidden()
                }
            }

            Section("訊息內容") {
                TextEditor(text: $message)
                    .frame(minHeight: 120)
            }

            Section {
                Text("可用變數：{name} 代表客戶姓名")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("編輯範本")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") {
                    isSaving = true
                    Task {
                        await onSave()
                        isSaving = false
                    }
                }
                .disabled(message.isEmpty || isSaving)
            }
        }
    }
}

// MARK: - Marketing Template Card

private struct MarketingTemplateCard: View {
    let template: MarketingTemplate
    var onEdit: (() -> Void)?

    var body: some View {
        Button {
            onEdit?()
        } label: {
            HStack(spacing: BTSpacing.md) {
                Image(systemName: templateIcon)
                    .font(.title3)
                    .foregroundStyle(BTColor.primary)
                    .frame(width: 40, height: 40)
                    .background(BTColor.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: BTRadius.sm))

                VStack(alignment: .leading, spacing: BTSpacing.xs) {
                    Text(template.name ?? template.typeName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(BTColor.textPrimary)

                    if !template.displayMessage.isEmpty {
                        Text(template.displayMessage)
                            .font(.caption)
                            .foregroundStyle(BTColor.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                BTBadge(
                    text: template.isEnabled ? "啟用中" : "未啟用",
                    color: template.isEnabled ? BTColor.success : BTColor.textTertiary
                )

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(BTColor.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .padding(BTSpacing.lg)
        .btCard()
    }

    private var templateIcon: String {
        switch template.type {
        case "birthday": return "gift.fill"
        case "revisit": return "arrow.uturn.left.circle.fill"
        case "promotion": return "tag.fill"
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
