import Foundation

@Observable
class PayrollManageStore {
    var providerId: String = ""

    // Payroll
    var commissionSettings: CommissionSettings?
    var payrollRecords: [PayrollRecord] = []
    var commissionTiers: [CommissionTier] = []
    var salaryConfigs: [SalaryConfig] = []

    var isLoading = false
    var error: String?

    private let api = APIClient.shared

    // MARK: - Commission Settings

    func loadCommissionSettings() async {
        guard !providerId.isEmpty else { return }
        do {
            commissionSettings = try await api.get(
                path: APIEndpoints.Payroll.commission,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateCommissionSettings(_ body: [String: Any]) async {
        isLoading = true
        do {
            commissionSettings = try await api.put(
                path: APIEndpoints.Payroll.commission,
                body: JSONBody(body)
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Payroll Records

    func loadPayroll(month: Int, year: Int) async {
        guard !providerId.isEmpty else { return }
        do {
            payrollRecords = try await api.get(
                path: APIEndpoints.Payroll.records,
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

    /// Calculate payroll from actual booking and sales records.
    ///
    /// Calculation flow per staff member:
    ///   1. baseSalary + allowances (from SalaryConfig)
    ///   2. + serviceCommission (from completed bookings × commission rate)
    ///      Commission rate fallback: staff×service override > staff custom > provider default
    ///   3. + productCommission (from product sales × product commission rate)
    ///   4. + designationBonus (from bookings where client chose this staff or is returning)
    ///   5. - deductions
    ///   6. = totalPay
    func calculatePayroll(month: Int, year: Int) async {
        guard !providerId.isEmpty else {
            self.error = "尚未載入商家資料"
            return
        }

        if salaryConfigs.isEmpty { await loadSalaryConfigs() }
        if commissionSettings == nil { await loadCommissionSettings() }

        isLoading = true
        do {
            // The server will do the real calculation (fetch bookings + sales + overrides)
            // We send salary configs so the server knows base salary + allowances
            let records: [[String: Any]] = salaryConfigs.map { config in
                let totalAllowances = (config.transportationAllowance ?? 0)
                    + (config.mealAllowance ?? 0)
                    + (config.otherAllowance ?? 0)
                let baseSalary = config.baseSalary ?? 0

                return [
                    "staffId": config.staffId,
                    "baseSalary": baseSalary,
                    "totalAllowances": totalAllowances,
                    "customCommissionRate": config.customCommissionRate as Any,
                    "customProductCommissionRate": config.customProductCommissionRate as Any,
                    "deductions": 0,
                    "deductionNote": ""
                ] as [String: Any]
            }

            // Server calculates serviceRevenue, serviceCommission, productRevenue,
            // productCommission, designationBonus from actual records
            payrollRecords = try await api.post(
                path: APIEndpoints.Payroll.generate,
                body: JSONBody([
                    "providerId": providerId,
                    "month": month,
                    "year": year,
                    "records": records
                ] as [String: Any])
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func updatePayrollStatus(status: String, month: Int, year: Int) async {
        isLoading = true
        do {
            let currentStatus = payrollRecords.first?.status?.rawValue ?? "draft"
            let _: [PayrollRecord] = try await api.patch(
                path: APIEndpoints.Payroll.status,
                body: JSONBody([
                    "providerId": providerId,
                    "year": year,
                    "month": month,
                    "fromStatus": currentStatus,
                    "toStatus": status
                ] as [String: Any])
            )
            await loadPayroll(month: month, year: year)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Commission Tiers

    func loadCommissionTiers() async {
        guard let settingId = commissionSettings?.id else { return }
        do {
            commissionTiers = try await api.get(
                path: APIEndpoints.Payroll.commissionTiers,
                queryItems: [URLQueryItem(name: "settingId", value: settingId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createCommissionTier(_ body: [String: Any]) async {
        isLoading = true
        do {
            let tier: CommissionTier = try await api.post(
                path: APIEndpoints.Payroll.commissionTiers,
                body: JSONBody(body)
            )
            commissionTiers.append(tier)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func updateCommissionTier(id: String, body: [String: Any]) async {
        isLoading = true
        do {
            let updated: CommissionTier = try await api.patch(
                path: APIEndpoints.Payroll.updateCommissionTier(id),
                body: JSONBody(body)
            )
            if let idx = commissionTiers.firstIndex(where: { $0.id == id }) {
                commissionTiers[idx] = updated
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteCommissionTier(id: String) async {
        do {
            try await api.delete(path: APIEndpoints.Payroll.deleteCommissionTier(id))
            commissionTiers.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Salary Configs

    func loadSalaryConfigs() async {
        guard !providerId.isEmpty else { return }
        do {
            salaryConfigs = try await api.get(
                path: APIEndpoints.Payroll.salaryConfigs,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateSalaryConfig(staffId: String, body: [String: Any]) async {
        isLoading = true
        do {
            let config: SalaryConfig = try await api.put(
                path: APIEndpoints.Payroll.salaryConfig(staffId),
                body: JSONBody(body)
            )
            if let idx = salaryConfigs.firstIndex(where: { $0.staffId == staffId }) {
                salaryConfigs[idx] = config
            } else {
                salaryConfigs.append(config)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
