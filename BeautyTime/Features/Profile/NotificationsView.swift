import SwiftUI

struct NotificationsView: View {
    @Environment(NotificationStore.self) private var notificationStore

    var body: some View {
        Group {
            if notificationStore.isLoading && notificationStore.notifications.isEmpty {
                LoadingView()
            } else if notificationStore.notifications.isEmpty {
                EmptyStateView(
                    icon: "bell.slash",
                    title: "沒有通知",
                    message: "目前沒有任何通知"
                )
            } else {
                List {
                    ForEach(notificationStore.notifications) { notification in
                        NotificationRow(notification: notification)
                            .onTapGesture {
                                Task { await notificationStore.markAsRead(notification) }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await notificationStore.deleteNotification(notification) }
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                            .listRowBackground(
                                notification.isRead == true
                                    ? BTColor.cardBackground
                                    : BTColor.secondaryBackground.opacity(0.5)
                            )
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("通知")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if notificationStore.unreadCount > 0 {
                    Button {
                        Task { await notificationStore.markAllAsRead() }
                    } label: {
                        Text("全部已讀")
                            .font(.subheadline)
                            .foregroundStyle(BTColor.primary)
                    }
                }
            }
        }
        .task { await notificationStore.loadNotifications() }
        .refreshable { await notificationStore.loadNotifications() }
    }
}

// MARK: - Notification Row

private struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: BTSpacing.md) {
            // Unread indicator
            Circle()
                .fill(notification.isRead == true ? Color.clear : BTColor.info)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                Text(notification.title)
                    .font(.subheadline.weight(notification.isRead == true ? .regular : .semibold))
                    .foregroundStyle(BTColor.textPrimary)

                if let body = notification.displayMessage {
                    Text(body)
                        .font(.caption)
                        .foregroundStyle(BTColor.textSecondary)
                        .lineLimit(2)
                }

                if let createdAt = notification.createdAt {
                    Text(Formatters.relativeDate(createdAt))
                        .font(.caption2)
                        .foregroundStyle(BTColor.textTertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, BTSpacing.xs)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
            .environment(NotificationStore())
    }
}
