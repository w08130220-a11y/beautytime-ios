import Foundation

@Observable
class OrderManageStore {
    var providerId: String = ""

    var orders: [Booking] = []
    var orderFilter: BookingStatus?
    var isLoading = false
    var error: String?

    private let api = APIClient.shared

    func loadOrders() async {
        guard !providerId.isEmpty else { return }
        do {
            var queryItems = [URLQueryItem(name: "providerId", value: providerId)]
            if let filter = orderFilter {
                queryItems.append(URLQueryItem(name: "status", value: filter.rawValue))
            }
            orders = try await api.get(
                path: APIEndpoints.Orders.list,
                queryItems: queryItems
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func confirmBooking(id: String) async {
        // Optimistic update: change status immediately, revert on failure
        guard let idx = orders.firstIndex(where: { $0.id == id }) else { return }
        let original = orders[idx]
        orders[idx] = original.withStatus(.confirmed)

        do {
            let _: SuccessResponse = try await api.patch(
                path: APIEndpoints.Orders.updateStatus(id),
                body: ["status": "confirmed"]
            )
        } catch {
            orders[idx] = original
            self.error = error.localizedDescription
        }
    }

    func completeBooking(id: String) async {
        guard let idx = orders.firstIndex(where: { $0.id == id }) else { return }
        let original = orders[idx]
        orders[idx] = original.withStatus(.completed)

        do {
            let _: SuccessResponse = try await api.patch(
                path: APIEndpoints.Orders.updateStatus(id),
                body: ["status": "completed"]
            )
        } catch {
            orders[idx] = original
            self.error = error.localizedDescription
        }
    }

    func cancelOrder(id: String, reason: String) async {
        guard let idx = orders.firstIndex(where: { $0.id == id }) else { return }
        let original = orders[idx]
        orders[idx] = original.withStatus(.cancelled)

        do {
            let _: SuccessResponse = try await api.patch(
                path: APIEndpoints.Orders.cancel(id),
                body: ["reason": reason]
            )
        } catch {
            orders[idx] = original
            self.error = error.localizedDescription
        }
    }
}
