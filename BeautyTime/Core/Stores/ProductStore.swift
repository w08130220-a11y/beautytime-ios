import Foundation

@Observable
class ProductStore {
    var providerId: String = ""

    var products: [Product] = []
    var sales: [ProductSale] = []
    var overrides: [ServiceCommissionOverride] = []
    var isLoading = false
    var error: String?

    private let api = APIClient.shared

    // MARK: - Products CRUD

    func loadProducts() async {
        guard !providerId.isEmpty else { return }
        do {
            products = try await api.get(
                path: APIEndpoints.Products.list,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createProduct(_ body: [String: Any]) async {
        isLoading = true
        do {
            let product: Product = try await api.post(
                path: APIEndpoints.Products.create,
                body: JSONBody(body)
            )
            products.append(product)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func updateProduct(id: String, body: [String: Any]) async {
        isLoading = true
        do {
            let updated: Product = try await api.patch(
                path: APIEndpoints.Products.update(id),
                body: JSONBody(body)
            )
            if let idx = products.firstIndex(where: { $0.id == id }) {
                products[idx] = updated
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteProduct(id: String) async {
        do {
            try await api.delete(path: APIEndpoints.Products.delete(id))
            products.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Product Sales

    func loadSales(month: Int, year: Int) async {
        guard !providerId.isEmpty else { return }
        do {
            sales = try await api.get(
                path: APIEndpoints.ProductSales.list,
                queryItems: [
                    URLQueryItem(name: "providerId", value: providerId),
                    URLQueryItem(name: "month", value: "\(month)"),
                    URLQueryItem(name: "year", value: "\(year)")
                ]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func recordSale(staffId: String, productId: String, quantity: Int, customerId: String?, bookingId: String?) async {
        guard let product = products.first(where: { $0.id == productId }) else { return }
        isLoading = true
        do {
            let totalAmount = product.price * Double(quantity)
            let commissionAmount = (product.hasCommission == true)
                ? totalAmount * (product.commissionRate ?? 0)
                : 0

            var body: [String: Any] = [
                "providerId": providerId,
                "staffId": staffId,
                "productId": productId,
                "quantity": quantity,
                "unitPrice": product.price,
                "totalAmount": totalAmount,
                "commissionAmount": commissionAmount,
                "saleDate": Formatters.dateFormatter.string(from: Date())
            ]
            if let customerId { body["customerId"] = customerId }
            if let bookingId { body["bookingId"] = bookingId }

            let sale: ProductSale = try await api.post(
                path: APIEndpoints.ProductSales.create,
                body: JSONBody(body)
            )
            sales.append(sale)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Service Commission Overrides

    func loadOverrides() async {
        guard !providerId.isEmpty else { return }
        do {
            overrides = try await api.get(
                path: APIEndpoints.CommissionOverrides.list,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createOverride(staffId: String, serviceId: String, rate: Double) async {
        isLoading = true
        do {
            let override: ServiceCommissionOverride = try await api.post(
                path: APIEndpoints.CommissionOverrides.create,
                body: JSONBody([
                    "providerId": providerId,
                    "staffId": staffId,
                    "serviceId": serviceId,
                    "commissionRate": rate
                ] as [String: Any])
            )
            overrides.append(override)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteOverride(id: String) async {
        do {
            try await api.delete(path: APIEndpoints.CommissionOverrides.delete(id))
            overrides.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
