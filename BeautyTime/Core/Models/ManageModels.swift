import Foundation

// MARK: - Dashboard Stats

struct DashboardStats: Codable {
    let todayBookings: Int?
    let todayRevenue: Double?
    let pendingBookings: Int?
    let totalCustomers: Int?
    let monthlyRevenue: Double?
    let monthlyBookings: Int?
}

// MARK: - Analytics

struct RevenueData: Codable {
    let totalRevenue: Double?
    let bookingCount: Int?
    let averageOrderValue: Double?
    let periodData: [PeriodRevenue]?
}

struct PeriodRevenue: Codable {
    let period: String?
    let revenue: Double?
    let count: Int?
}

struct ServiceRevenueData: Codable {
    let serviceName: String?
    let revenue: Double?
    let count: Int?
}

struct ReturnRateData: Codable {
    let returnRate: Double?
    let totalCustomers: Int?
    let returningCustomers: Int?
}

struct CustomerMixData: Codable {
    let newCustomers: Int?
    let returningCustomers: Int?
    let newPercentage: Double?
    let returningPercentage: Double?
}

struct UnitPriceData: Codable {
    let period: String?
    let averageUnitPrice: Double?
    let count: Int?
}

// MARK: - Commission & Payroll

struct CommissionSettings: Codable {
    let id: String?
    let providerId: String?
    let salaryModel: String?
    let defaultCommissionRate: Double?
    let commissionType: CommissionType?
    let productCommissionRate: Double?
}

enum CommissionType: String, Codable {
    case flat, tiered
}

struct PayrollRecord: Codable, Identifiable {
    let id: String
    let providerId: String?
    let staffId: String?
    let month: Int?
    let year: Int?
    let baseSalary: Double?
    let totalAllowances: Double?
    let serviceRevenue: Double?
    let serviceCommission: Double?
    let productRevenue: Double?
    let productCommission: Double?
    let designationBonus: Double?
    let commission: Double?
    let deductions: Double?
    let deductionNote: String?
    let totalPay: Double?
    let totalAmount: Double?
    let status: PayrollStatus?
    let staff: StaffMember?

    var displayTotal: Double {
        totalPay ?? totalAmount ?? 0
    }
}

enum PayrollStatus: String, Codable {
    case draft, confirmed, paid
}

struct CommissionTier: Codable, Identifiable {
    let id: String
    let settingId: String?
    let minRevenue: Double?
    let maxRevenue: Double?
    let rate: Double?
}

struct SalaryConfig: Codable, Identifiable {
    var id: String { staffId }
    let staffId: String
    let providerId: String?
    let baseSalary: Double?
    let transportationAllowance: Double?
    let mealAllowance: Double?
    let otherAllowance: Double?
    let useCustomCommission: Bool?
    let customCommissionRate: Double?
    let designationBonus: Double?
    let staff: StaffMember?
}

// MARK: - Customer

struct CustomerNote: Codable, Identifiable {
    let id: String?
    let customerId: String?
    let providerId: String?
    let content: String?
    let createdAt: Date?
}

struct CustomerWithNotes: Codable, Identifiable {
    let id: String
    let customer: User?
    let bookingCount: Int?
    let lastVisit: Date?
    let notes: [CustomerNote]?
}

// MARK: - Voucher

struct VoucherPlan: Codable, Identifiable {
    let id: String
    let providerId: String?
    let type: VoucherType?
    let name: String
    let description: String?
    let originalPrice: Double?
    let sellingPrice: Double?
    let sessionsTotal: Int?
    let bonusAmount: Double?
    let validDays: Int?
    let applicableServices: [String]?
    let maxSales: Int?
    let soldCount: Int?
    let isActive: Bool?
}

enum VoucherType: String, Codable {
    case session, storedValue = "stored_value", package
}

struct CustomerVoucher: Codable, Identifiable {
    let id: String
    let planId: String?
    let customerId: String?
    let providerId: String?
    let purchasePrice: Double?
    let sessionsRemaining: Int?
    let balanceRemaining: Double?
    let packageRemaining: [String: Int]?
    let status: VoucherStatus?
    let purchasedAt: Date?
    let expiresAt: Date?
    let lastUsedAt: Date?
    let plan: VoucherPlan?
    let provider: Provider?
}

enum VoucherStatus: String, Codable {
    case pending, active, frozen, expired, refunded
}

struct VoucherTransaction: Codable, Identifiable {
    let id: String
    let voucherId: String?
    let bookingId: String?
    let type: VoucherTransactionType?
    let sessionsUsed: Int?
    let amountUsed: Double?
    let upgradeFee: Double?
    let serviceId: String?
    let staffId: String?
    let note: String?
    let createdAt: Date?
}

enum VoucherTransactionType: String, Codable {
    case redeem, upgrade, refund, extend, freeze, unfreeze
}

struct VoucherTokenResponse: Codable {
    let token: String
    let expiresAt: Date?
}

struct VoucherVerifyResponse: Codable {
    let valid: Bool?
    let voucher: CustomerVoucher?
    let plan: VoucherPlan?
    let message: String?
}

struct VoucherPurchaseResponse: Codable {
    let voucher: CustomerVoucher?
    let payment: VoucherPaymentInfo?
}

struct VoucherPaymentInfo: Codable {
    let transactionId: String?
    let amount: Double?
    let planName: String?
}

struct VoucherLiability: Codable {
    let totalLiability: Double?
    let totalSessions: Int?
    let totalBalance: Double?
    let planCount: Int?
}

struct VoucherLiabilityByCustomer: Codable, Identifiable {
    let id: String
    let customerId: String?
    let customerName: String?
    let totalSessions: Int?
    let totalBalance: Double?
    let voucherCount: Int?
}

// MARK: - Common

struct SuccessResponse: Codable {
    let success: Bool
}

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let total: Int?
    let page: Int?
    let limit: Int?
}
