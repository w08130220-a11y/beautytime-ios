import Foundation

// ManageStore now handles provider-level settings only.
// Dashboard data → DashboardStore
// Orders → OrderManageStore
// Customers → CustomerManageStore

@Observable
class ManageStore {
    var providerId: String = ""

    // Services
    var services: [Service] = []

    // Portfolio
    var portfolio: [PortfolioItem] = []

    // Business Hours
    var businessHours: [BusinessHour] = []

    // Marketing Templates
    var marketingTemplates: [MarketingTemplate] = []

    var isLoading = false
    var error: String?

    private let api = APIClient.shared

    // MARK: - Services CRUD

    func loadServices() async {
        guard !providerId.isEmpty else { return }
        do {
            services = try await api.get(
                path: APIEndpoints.Services.list,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createService(_ body: [String: Any]) async {
        isLoading = true
        do {
            let service: Service = try await api.post(path: APIEndpoints.Services.create, body: JSONBody(body))
            services.append(service)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func updateService(id: String, body: [String: Any]) async {
        isLoading = true
        do {
            let updated: Service = try await api.patch(path: APIEndpoints.Services.update(id), body: JSONBody(body))
            if let idx = services.firstIndex(where: { $0.id == id }) {
                services[idx] = updated
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteService(id: String) async {
        do {
            try await api.delete(path: APIEndpoints.Services.delete(id))
            services.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Portfolio

    func loadPortfolio() async {
        guard !providerId.isEmpty else { return }
        do {
            portfolio = try await api.get(
                path: APIEndpoints.Portfolio.list,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deletePortfolioItem(id: String) async {
        do {
            try await api.delete(path: APIEndpoints.Portfolio.delete(id))
            portfolio.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createPortfolioItem(beforeUrl: String?, afterUrl: String?, description: String?, styleTags: [String]?) async {
        isLoading = true
        do {
            var body: [String: Any] = ["providerId": providerId]
            if let beforeUrl { body["beforePhotoUrl"] = beforeUrl }
            if let afterUrl { body["afterPhotoUrl"] = afterUrl }
            if let description { body["description"] = description }
            if let styleTags { body["styleTags"] = styleTags }
            let item: PortfolioItem = try await api.post(
                path: APIEndpoints.Portfolio.create,
                body: JSONBody(body)
            )
            portfolio.append(item)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func uploadPortfolioImage(fileName: String, contentType: String, fileData: String) async -> String? {
        do {
            let response: ImageUploadResponse = try await api.post(
                path: APIEndpoints.Portfolio.upload,
                body: JSONBody([
                    "providerId": providerId,
                    "fileName": fileName,
                    "contentType": contentType,
                    "fileData": fileData
                ] as [String: Any])
            )
            return response.url ?? response.imageUrl
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    // MARK: - Business Hours

    func loadBusinessHours() async {
        guard !providerId.isEmpty else { return }
        do {
            businessHours = try await api.get(
                path: APIEndpoints.Hours.get,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateBusinessHours(_ hours: [BusinessHour]) async {
        isLoading = true
        do {
            let body = JSONBody([
                "providerId": providerId,
                "hours": hours.map { h -> [String: Any] in
                    var dict: [String: Any] = [
                        "dayOfWeek": h.dayOfWeek,
                        "isOpen": h.isOpen ?? false
                    ]
                    if let openTime = h.openTime { dict["openTime"] = openTime }
                    if let closeTime = h.closeTime { dict["closeTime"] = closeTime }
                    return dict
                }
            ] as [String: Any])
            let _: [BusinessHour] = try await api.put(
                path: APIEndpoints.Hours.update,
                body: body
            )
            await loadBusinessHours()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Marketing Templates

    func loadMarketingTemplates() async {
        guard !providerId.isEmpty else { return }
        do {
            marketingTemplates = try await api.get(
                path: APIEndpoints.Marketing.templates,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func saveMarketingTemplates() async {
        isLoading = true
        do {
            marketingTemplates = try await api.put(
                path: APIEndpoints.Marketing.save,
                body: JSONBody([
                    "providerId": providerId,
                    "templates": marketingTemplates.map { template -> [String: Any] in
                        var dict: [String: Any] = [
                            "type": template.type ?? "",
                            "message": template.displayMessage,
                            "enabled": template.isEnabled
                        ]
                        dict["id"] = template.id
                        dict["providerId"] = providerId
                        return dict
                    }
                ] as [String: Any])
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func updateMarketingTemplate(id: String, message: String?, enabled: Bool?) async {
        isLoading = true
        do {
            var body: [String: Any] = [:]
            if let message { body["message"] = message }
            if let enabled { body["enabled"] = enabled }
            let updated: MarketingTemplate = try await api.patch(
                path: APIEndpoints.Marketing.update(id),
                body: JSONBody(body)
            )
            if let idx = marketingTemplates.firstIndex(where: { $0.id == id }) {
                marketingTemplates[idx] = updated
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Provider Image Upload

    func uploadProviderImage(fileName: String, contentType: String, fileData: String) async -> String? {
        do {
            let response: ImageUploadResponse = try await api.post(
                path: APIEndpoints.Settings.providerImage,
                body: JSONBody([
                    "providerId": providerId,
                    "fileName": fileName,
                    "contentType": contentType,
                    "fileData": fileData
                ] as [String: Any])
            )
            return response.url ?? response.imageUrl
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }
}
