import Foundation

@Observable
class AnalyticsManageStore {
    var providerId: String = ""

    // Analytics
    var revenueData: RevenueData?
    var serviceRevenue: [ServiceRevenueData] = []
    var returnRate: ReturnRateData?
    var customerMix: CustomerMixData?
    var unitPriceData: [UnitPriceData] = []

    var isLoading = false
    var error: String?

    private let api = APIClient.shared

    // MARK: - Analytics

    func loadAnalytics() async {
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
            async let serviceRevenueTask: [ServiceRevenueData] = api.get(
                path: APIEndpoints.Analytics.serviceRevenue,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
            async let returnRateTask: ReturnRateData = api.get(
                path: APIEndpoints.Analytics.returnRate,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
            async let customerMixTask: CustomerMixData = api.get(
                path: APIEndpoints.Analytics.customerMix,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )

            revenueData = try await revenueTask
            serviceRevenue = try await serviceRevenueTask
            returnRate = try await returnRateTask
            customerMix = try await customerMixTask
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Unit Price Analytics

    func loadUnitPriceAnalytics() async {
        guard !providerId.isEmpty else { return }
        do {
            unitPriceData = try await api.get(
                path: APIEndpoints.Analytics.unitPrice,
                queryItems: [
                    URLQueryItem(name: "providerId", value: providerId),
                    URLQueryItem(name: "period", value: "6")
                ]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }
}
