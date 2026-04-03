import Foundation

@Observable
class DashboardStore {
    var providerId: String = ""

    var revenueData: RevenueData?
    var todayBookings: [Booking] = []
    var dashboardStats: DashboardStats?
    var isLoading = false
    var error: String?

    private let api = APIClient.shared

    func loadDashboard() async {
        guard !providerId.isEmpty else { return }
        isLoading = true
        do {
            async let revenueTask: RevenueData = api.get(
                path: APIEndpoints.Analytics.revenue,
                queryItems: [
                    URLQueryItem(name: "providerId", value: providerId),
                    URLQueryItem(name: "period", value: "month")
                ]
            )
            async let bookingsTask: [Booking] = api.get(
                path: APIEndpoints.Bookings.provider(providerId)
            )

            revenueData = try await revenueTask
            todayBookings = try await bookingsTask
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadDashboardStats() async {
        guard !providerId.isEmpty else { return }
        isLoading = true
        do {
            async let statsTask: DashboardStats = api.get(
                path: APIEndpoints.Stats.dashboard,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
            async let bookingsTask: [Booking] = api.get(
                path: APIEndpoints.Bookings.provider(providerId)
            )

            dashboardStats = try await statsTask
            todayBookings = try await bookingsTask
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
