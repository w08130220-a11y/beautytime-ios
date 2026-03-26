import Foundation

@Observable
class ManageStore {
    var providerId: String = ""

    // Dashboard
    var revenueData: RevenueData?
    var todayBookings: [Booking] = []
    var dashboardStats: DashboardStats?

    // Services
    var services: [Service] = []

    // Orders
    var orders: [Booking] = []
    var orderFilter: BookingStatus?

    // Customers
    var customers: [CustomerWithNotes] = []

    // Portfolio
    var portfolio: [PortfolioItem] = []

    // Business Hours
    var businessHours: [BusinessHour] = []

    // Marketing Templates
    var marketingTemplates: [MarketingTemplate] = []

    var isLoading = false
    var error: String?

    private let api = APIClient.shared

    // MARK: - Dashboard

    func loadDashboard() async {
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
                path: APIEndpoints.Bookings.provider,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )

            revenueData = try await revenueTask
            todayBookings = try await bookingsTask
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Dashboard Stats

    func loadDashboardStats() async {
        isLoading = true
        do {
            async let statsTask: DashboardStats = api.get(
                path: APIEndpoints.Stats.dashboard,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
            async let bookingsTask: [Booking] = api.get(
                path: APIEndpoints.Bookings.provider,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )

            dashboardStats = try await statsTask
            todayBookings = try await bookingsTask
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Services CRUD

    func loadServices() async {
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

    // MARK: - Orders

    func loadOrders() async {
        do {
            var queryItems = [URLQueryItem(name: "providerId", value: providerId)]
            if let filter = orderFilter {
                queryItems.append(URLQueryItem(name: "status", value: filter.rawValue))
            }
            orders = try await api.get(
                path: APIEndpoints.Bookings.provider,
                queryItems: queryItems
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func confirmBooking(id: String) async {
        do {
            let updated: Booking = try await api.patch(path: APIEndpoints.Bookings.confirm(id), body: ["status": "confirmed"])
            if let idx = orders.firstIndex(where: { $0.id == id }) {
                orders[idx] = updated
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func completeBooking(id: String) async {
        do {
            let updated: Booking = try await api.patch(path: APIEndpoints.Bookings.complete(id), body: ["status": "completed"])
            if let idx = orders.firstIndex(where: { $0.id == id }) {
                orders[idx] = updated
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Customers

    func loadCustomers() async {
        do {
            customers = try await api.get(
                path: APIEndpoints.Customers.list,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func addCustomerNote(customerId: String, content: String) async {
        do {
            let _: CustomerNote = try await api.post(
                path: APIEndpoints.Customers.addNote,
                body: ["customerId": customerId, "providerId": providerId, "content": content]
            )
            await loadCustomers()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteCustomerNote(noteId: String) async {
        do {
            try await api.delete(path: APIEndpoints.Customers.deleteNote(noteId))
            await loadCustomers()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Portfolio

    func loadPortfolio() async {
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
            businessHours = try await api.put(
                path: APIEndpoints.Hours.update,
                body: hours
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Marketing Templates

    func loadMarketingTemplates() async {
        do {
            marketingTemplates = try await api.get(
                path: APIEndpoints.Marketing.templates,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
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
