import Foundation

@Observable
class OrderManageStore {
    var providerId: String = ""

    var orders: [Booking] = []
    var orderFilter: BookingStatus?
    var isLoading = false
    var error: String?

    private let api = APIClient.shared
    private let alertService = BookingAlertService.shared

    /// Track known booking IDs so we can detect new ones on refresh
    private var knownBookingIds: Set<String> = []

    func loadOrders() async {
        guard !providerId.isEmpty else { return }
        do {
            var queryItems = [URLQueryItem(name: "providerId", value: providerId)]
            if let filter = orderFilter {
                queryItems.append(URLQueryItem(name: "status", value: filter.rawValue))
            }
            let newOrders: [Booking] = try await api.get(
                path: APIEndpoints.Orders.list,
                queryItems: queryItems
            )

            // Detect new bookings and alert
            if !knownBookingIds.isEmpty {
                for booking in newOrders where !knownBookingIds.contains(booking.id) {
                    alertService.showNewBookingAlert(
                        customerName: booking.customer?.fullName ?? "顧客",
                        serviceName: booking.service?.name ?? "服務",
                        date: booking.date ?? "",
                        time: booking.time ?? ""
                    )
                }
            }

            orders = newOrders
            knownBookingIds = Set(newOrders.map(\.id))
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
