import Foundation

@Observable
class CustomerManageStore {
    var providerId: String = ""

    var customers: [CustomerWithNotes] = []
    var isLoading = false
    var error: String?

    private let api = APIClient.shared

    func loadCustomers() async {
        guard !providerId.isEmpty else { return }
        isLoading = true
        do {
            customers = try await api.get(
                path: APIEndpoints.Customers.list,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func addCustomerNote(customerId: String, content: String) async {
        do {
            let _: CustomerNote = try await api.post(
                path: APIEndpoints.Customers.addNote(customerId) + "?providerId=\(providerId)",
                body: ["providerId": providerId, "content": content]
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
}
