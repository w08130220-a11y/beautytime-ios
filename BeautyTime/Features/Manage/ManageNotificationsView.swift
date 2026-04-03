import SwiftUI

struct ManageNotificationsView: View {
    @State private var newBookingEnabled = true
    @State private var cancellationEnabled = true
    @State private var reviewEnabled = true
    @State private var matchEnabled = true
    @State private var marketingEnabled = false

    var body: some View {
        List {
            Section {
                Text("設定您想要接收的通知類型")
                    .font(.caption)
                    .foregroundStyle(BTColor.textTertiary)
            }

            Section("預約相關") {
                Toggle(isOn: $newBookingEnabled) {
                    NotificationToggleLabel(
                        icon: "calendar.badge.plus",
                        title: "新預約通知",
                        description: "有新預約時通知您"
                    )
                }
                .tint(BTColor.primary)

                Toggle(isOn: $cancellationEnabled) {
                    NotificationToggleLabel(
                        icon: "calendar.badge.minus",
                        title: "預約取消通知",
                        description: "顧客取消預約時通知您"
                    )
                }
                .tint(BTColor.primary)
            }

            Section("評價與媒合") {
                Toggle(isOn: $reviewEnabled) {
                    NotificationToggleLabel(
                        icon: "star.bubble",
                        title: "評價通知",
                        description: "收到新評價時通知您"
                    )
                }
                .tint(BTColor.primary)

                Toggle(isOn: $matchEnabled) {
                    NotificationToggleLabel(
                        icon: "person.2.wave.2",
                        title: "媒合通知",
                        description: "有新的媒合需求時通知您"
                    )
                }
                .tint(BTColor.primary)
            }

            Section("行銷") {
                Toggle(isOn: $marketingEnabled) {
                    NotificationToggleLabel(
                        icon: "megaphone",
                        title: "行銷通知",
                        description: "行銷活動與優惠資訊"
                    )
                }
                .tint(BTColor.primary)
            }
        }
        .navigationTitle("通知設定")
    }
}

// MARK: - Notification Toggle Label

private struct NotificationToggleLabel: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: BTSpacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(BTColor.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(BTColor.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(BTColor.textTertiary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ManageNotificationsView()
    }
}
