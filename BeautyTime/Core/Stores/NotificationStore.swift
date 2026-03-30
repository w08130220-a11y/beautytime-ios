import Foundation

@Observable
class NotificationStore {
    var notifications: [AppNotification] = []
    var isLoading = false
    var error: String?

    var unreadCount: Int {
        notifications.filter { $0.isRead != true }.count
    }

    private let api = APIClient.shared

    func loadNotifications() async {
        isLoading = true
        do {
            notifications = try await api.get(path: APIEndpoints.Notifications.list)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func fetchUnreadCount() async -> Int {
        do {
            let response: UnreadCountResponse = try await api.get(
                path: APIEndpoints.Notifications.unreadCount
            )
            return response.count
        } catch {
            return unreadCount
        }
    }

    func markAsRead(_ notification: AppNotification) async {
        guard notification.isRead != true else { return }
        do {
            let _: AppNotification = try await api.patch(
                path: APIEndpoints.Notifications.markRead(notification.id)
            )
            if notifications.contains(where: { $0.id == notification.id }) {
                await loadNotifications()
            }
        } catch {}
    }

    func markAllAsRead() async {
        do {
            let _: [String: Bool] = try await api.post(
                path: APIEndpoints.Notifications.readAll,
                body: JSONBody([:])
            )
            await loadNotifications()
        } catch {}
    }

    func deleteNotification(_ notification: AppNotification) async {
        do {
            try await api.delete(path: APIEndpoints.Notifications.delete(notification.id))
            notifications.removeAll { $0.id == notification.id }
        } catch {}
    }
}
