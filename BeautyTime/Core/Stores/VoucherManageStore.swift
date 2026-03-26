import Foundation

@Observable
class VoucherManageStore {
    var providerId: String = ""

    // Voucher Plans
    var voucherPlans: [VoucherPlan] = []
    var providerVouchers: [CustomerVoucher] = []
    var soldVouchers: [CustomerVoucher] = []
    var voucherLiability: VoucherLiability?
    var liabilityByCustomer: [VoucherLiabilityByCustomer] = []

    var isLoading = false
    var error: String?

    private let api = APIClient.shared

    // MARK: - Voucher Plans

    func loadVoucherPlans() async {
        do {
            voucherPlans = try await api.get(
                path: APIEndpoints.Vouchers.plans,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createVoucherPlan(_ body: [String: Any]) async {
        isLoading = true
        do {
            let plan: VoucherPlan = try await api.post(path: APIEndpoints.Vouchers.createPlan, body: JSONBody(body))
            voucherPlans.append(plan)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteVoucherPlan(id: String) async {
        do {
            try await api.delete(path: APIEndpoints.Vouchers.deletePlan(id))
            voucherPlans.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Sold Vouchers

    func loadSoldVouchers() async {
        do {
            soldVouchers = try await api.get(
                path: APIEndpoints.Vouchers.sold,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Voucher Liability

    func loadVoucherLiability() async {
        do {
            voucherLiability = try await api.get(
                path: APIEndpoints.Vouchers.liability,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadLiabilityByCustomer() async {
        do {
            liabilityByCustomer = try await api.get(
                path: APIEndpoints.Vouchers.liabilityByCustomer,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }
}
