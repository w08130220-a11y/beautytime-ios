import Foundation
import SwiftUI

// MARK: - User & Profile

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String?
    let avatarUrl: String?
    let phone: String?
    let phoneVerified: Bool?
    let role: UserRole
    let preferredLocale: AppLocale?
    let surveyCompleted: Bool?
    let createdAt: Date?
}

enum UserRole: String, Codable {
    case customer, provider, both
}

enum AppLocale: String, Codable {
    case zhTW = "zh-TW"
    case en
}

// MARK: - Provider

struct Provider: Codable, Identifiable {
    let id: String
    let userId: String?
    let name: String
    let category: ServiceCategory?
    let description: String?
    let address: String?
    let city: String?
    let district: String?
    let phone: String?
    let imageUrl: String?
    let rating: Double?
    let reviewCount: Int?
    let isVerified: Bool?
    let isActive: Bool?
    let depositRate: Double?
    let instagramUrl: String?
    let reviewNote: String?
    let createdAt: Date?
}

// MARK: - Staff

struct StaffMember: Codable, Identifiable {
    let id: String
    let providerId: String
    let userId: String?
    let role: StaffRole?
    let name: String
    let title: String?
    let photoUrl: String?
    let specialties: [String]?
    let rating: Double?
    let reviewCount: Int?
    let isActive: Bool?
}

enum StaffRole: String, Codable {
    case owner, manager, seniorDesigner = "senior_designer"
    case designer, assistant
}

// MARK: - Service

struct Service: Codable, Identifiable {
    let id: String
    let providerId: String?
    let name: String
    let description: String?
    let category: String?
    let duration: Int?      // minutes
    let price: Double?
    let isAvailable: Bool?
    let sortOrder: Int?
}

// MARK: - Booking

struct Booking: Identifiable {
    let id: String
    let customerId: String?
    let providerId: String?
    let serviceId: String?
    let staffId: String?
    let date: String?
    let time: String?
    let duration: Int?
    let totalPrice: Double?
    let depositAmount: Double?
    let depositPaid: Bool?
    let status: BookingStatus?
    let cancellationReason: String?
    let note: String?
    let createdAt: Date?
    let service: Service?
    let provider: Provider?
    let staff: StaffMember?
    let customer: User?
}

extension Booking: Codable {
    enum CodingKeys: String, CodingKey {
        case id, customerId, providerId, serviceId, staffId
        case date, time, duration, totalPrice, depositAmount, depositPaid
        case status, cancellationReason, note, createdAt, customer
        case service, services
        case provider, providers
        case staff, staffMembers
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        customerId = try c.decodeIfPresent(String.self, forKey: .customerId)
        providerId = try c.decodeIfPresent(String.self, forKey: .providerId)
        serviceId = try c.decodeIfPresent(String.self, forKey: .serviceId)
        staffId = try c.decodeIfPresent(String.self, forKey: .staffId)
        date = try c.decodeIfPresent(String.self, forKey: .date)
        time = try c.decodeIfPresent(String.self, forKey: .time)
        duration = try c.decodeIfPresent(Int.self, forKey: .duration)
        totalPrice = try c.decodeIfPresent(Double.self, forKey: .totalPrice)
        depositAmount = try c.decodeIfPresent(Double.self, forKey: .depositAmount)
        depositPaid = try c.decodeIfPresent(Bool.self, forKey: .depositPaid)
        status = try c.decodeIfPresent(BookingStatus.self, forKey: .status)
        cancellationReason = try c.decodeIfPresent(String.self, forKey: .cancellationReason)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        customer = try c.decodeIfPresent(User.self, forKey: .customer)
        service = try c.decodeIfPresent(Service.self, forKey: .service)
            ?? c.decodeIfPresent(Service.self, forKey: .services)
        provider = try c.decodeIfPresent(Provider.self, forKey: .provider)
            ?? c.decodeIfPresent(Provider.self, forKey: .providers)
        staff = try c.decodeIfPresent(StaffMember.self, forKey: .staff)
            ?? c.decodeIfPresent(StaffMember.self, forKey: .staffMembers)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(customerId, forKey: .customerId)
        try c.encodeIfPresent(providerId, forKey: .providerId)
        try c.encodeIfPresent(serviceId, forKey: .serviceId)
        try c.encodeIfPresent(staffId, forKey: .staffId)
        try c.encodeIfPresent(date, forKey: .date)
        try c.encodeIfPresent(time, forKey: .time)
        try c.encodeIfPresent(duration, forKey: .duration)
        try c.encodeIfPresent(totalPrice, forKey: .totalPrice)
        try c.encodeIfPresent(depositAmount, forKey: .depositAmount)
        try c.encodeIfPresent(depositPaid, forKey: .depositPaid)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(cancellationReason, forKey: .cancellationReason)
        try c.encodeIfPresent(note, forKey: .note)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(customer, forKey: .customer)
        try c.encodeIfPresent(service, forKey: .service)
        try c.encodeIfPresent(provider, forKey: .provider)
        try c.encodeIfPresent(staff, forKey: .staff)
    }
}

enum BookingStatus: String, Codable {
    case pending, confirmed, completed, cancelled, disputed
}

// MARK: - Review

struct Review: Codable, Identifiable {
    let id: String
    let bookingId: String?
    let customerId: String?
    let providerId: String?
    let staffId: String?
    let rating: Int
    let comment: String?
    let imageUrls: [String]?
    let createdAt: Date?
    let customer: User?
}

// MARK: - Payment

struct Payment: Codable, Identifiable {
    let id: String
    let bookingId: String?
    let customerId: String?
    let amount: Double?
    let depositAmount: Double?
    let paymentMethod: String?
    let status: PaymentStatus?
    let transactionId: String?
    let ecpayTradeNo: String?
    let paidAt: Date?
}

enum PaymentStatus: String, Codable {
    case pending, paid, refunded, failed
}

struct PaymentResponse: Codable {
    let html: String?
    let merchantTradeNo: String?
    let payment: Payment?
}

struct PaymentResult: Codable {
    let status: PaymentStatus?
    let payment: Payment?
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

// MARK: - Match

struct MatchRequest: Codable, Identifiable {
    let id: String
    let customerId: String?
    let serviceType: String?
    let preferredDate: String?
    let preferredTime: String?
    let locationCity: String?
    let locationDistrict: String?
    let budgetMin: Double?
    let budgetMax: Double?
    let photoUrl: String?
    let note: String?
    let status: MatchStatus?
    let createdAt: Date?
    let expiresAt: Date?
    let offers: [MatchOffer]?
}

enum MatchStatus: String, Codable {
    case open, matched, closed
}

struct MatchOffer: Codable, Identifiable {
    let id: String
    let requestId: String?
    let providerId: String?
    let quotedPrice: Double?
    let availableSlots: [String]?
    let portfolioUrls: [String]?
    let message: String?
    let status: MatchOfferStatus?
    let createdAt: Date?
    let provider: Provider?
}

enum MatchOfferStatus: String, Codable {
    case pending, accepted, rejected
}

// MARK: - Portfolio

struct PortfolioItem: Codable, Identifiable {
    let id: String
    let providerId: String?
    let beforePhotoUrl: String?
    let afterPhotoUrl: String?
    let description: String?
    let styleTags: [String]?
    let createdAt: Date?
}

// MARK: - Business Hours

struct BusinessHour: Codable, Identifiable {
    let id: String
    let providerId: String?
    let dayOfWeek: Int         // 0=Sunday, 6=Saturday
    let openTime: String?      // "09:00"
    let closeTime: String?     // "18:00"
    let isOpen: Bool?
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
    let commission: Double?
    let deductions: Double?
    let totalAmount: Double?
    let status: PayrollStatus?
    let staff: StaffMember?
}

enum PayrollStatus: String, Codable {
    case draft, confirmed, paid
}

// MARK: - Coupon

struct Coupon: Codable, Identifiable {
    let id: String
    let code: String?
    let description: String?
    let discountType: DiscountType?
    let discountValue: Double?
    let minOrderAmount: Double?
    let validFrom: Date?
    let validUntil: Date?
    let isActive: Bool?
}

enum DiscountType: String, Codable {
    case percentage, fixed
}

struct CouponVerifyResponse: Codable {
    let valid: Bool
    let coupon: Coupon?
    let message: String?
}

// MARK: - Notification

struct AppNotification: Codable, Identifiable {
    let id: String
    let userId: String?
    let title: String
    let message: String?
    let body: String?
    let type: String?
    let link: String?
    let isRead: Bool?
    let createdAt: Date?

    var displayMessage: String? { message ?? body }
}

// MARK: - Announcement

struct Announcement: Codable, Identifiable {
    let id: String
    let title: String?
    let content: String?
    let type: String?
    let isActive: Bool?
    let createdAt: Date?
}

// MARK: - Availability

struct AvailableStaff: Codable {
    let staff: StaffMember
    let availableSlots: [String]?   // ["09:00", "10:00", ...]
}

struct AvailableDate: Codable {
    let date: String    // "YYYY-MM-DD"
    let available: Bool
}

// MARK: - Auth Responses

struct AuthResponse: Codable {
    let token: String?
    let user: User?
}

struct OTPResponse: Codable {
    let message: String?
    let success: Bool?
}

struct EmailCheckResponse: Codable {
    let exists: Bool
}

// MARK: - Customer Note

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

// MARK: - Popular Tag

struct PopularTag: Codable {
    let tag: String
    let count: Int
}

// MARK: - Paginated Response

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let total: Int?
    let page: Int?
    let limit: Int?
}

// MARK: - Favorite

struct Favorite: Identifiable {
    let id: String
    let userId: String?
    let providerId: String?
    let provider: Provider?
    let createdAt: Date?
}

extension Favorite: Codable {
    enum CodingKeys: String, CodingKey {
        case id, userId, providerId, provider, providers, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        userId = try c.decodeIfPresent(String.self, forKey: .userId)
        providerId = try c.decodeIfPresent(String.self, forKey: .providerId)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        provider = try c.decodeIfPresent(Provider.self, forKey: .provider)
            ?? c.decodeIfPresent(Provider.self, forKey: .providers)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(userId, forKey: .userId)
        try c.encodeIfPresent(providerId, forKey: .providerId)
        try c.encodeIfPresent(provider, forKey: .provider)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}

struct FavoriteToggleResponse: Codable {
    let favorited: Bool
}

struct FavoriteCheckResponse: Codable {
    let favorited: Bool
}

// MARK: - Voucher Purchase Response

struct VoucherPurchaseResponse: Codable {
    let voucher: CustomerVoucher?
    let payment: VoucherPaymentInfo?
}

struct VoucherPaymentInfo: Codable {
    let transactionId: String?
    let amount: Double?
    let planName: String?
}

// MARK: - Booking Pay Response

struct BookingPayResponse: Codable {
    let payment: BookingPaymentDetail?
}

struct BookingPaymentDetail: Codable {
    let merchantTradeNo: String?
    let amount: Double?
    let serviceName: String?
    let bookingId: String?
}

// MARK: - API Response Wrappers (matching actual backend response format)

struct ProvidersResponse: Codable {
    let providers: [Provider]
    let total: Int?
}

struct ProviderDetailResponse: Codable {
    let provider: Provider
    let services: [Service]?
    let staff: [StaffMember]?
    let reviews: [Review]?
    let portfolio: [PortfolioItem]?
    let businessHours: [BusinessHour]?
    let voucherPlans: [VoucherPlan]?
}

// PopularTag is already defined above

// MARK: - Staff Invitation

enum InvitationStatus: String, Codable {
    case pending, accepted, rejected, expired
}

struct StaffInvitation: Codable, Identifiable {
    let id: String
    let providerId: String?
    let staffId: String?
    let inviteeId: String?
    let staffEmail: String?
    let email: String?
    let role: StaffRole?
    let status: InvitationStatus?
    let providerName: String?
    let staffName: String?
    let createdAt: Date?
    let provider: Provider?
}

// MARK: - Staff Schedule

struct StaffSchedule: Codable, Identifiable {
    let id: String
    let staffId: String?
    let dayOfWeek: Int?
    let startTime: String?
    let endTime: String?
    let isAvailable: Bool?
}

// MARK: - Staff Exception

struct StaffException: Codable, Identifiable {
    let id: String
    let staffId: String?
    let date: String?
    let type: String?       // sick, vacation, personal, other
    let note: String?
    let startTime: String?
    let endTime: String?
    let reason: String?
    let isBlocked: Bool?
}

// MARK: - Dashboard Stats

struct DashboardStats: Codable {
    let todayBookings: Int?
    let todayRevenue: Double?
    let pendingBookings: Int?
    let totalCustomers: Int?
    let monthlyRevenue: Double?
    let monthlyBookings: Int?
}

// MARK: - Staff Performance

struct StaffPerformance: Codable, Identifiable {
    let id: String
    let name: String?
    let bookingCount: Int?
    let revenue: Double?
    let rating: Double?
    let reviewCount: Int?
}

// MARK: - Voucher Liability

struct VoucherLiability: Codable {
    let totalLiability: Double?
    let totalSessions: Int?
    let totalBalance: Double?
    let planCount: Int?
}

// MARK: - Marketing Template

struct MarketingTemplate: Codable, Identifiable {
    let id: String
    let name: String?
    let content: String?
    let type: String?
    let isActive: Bool?
    let createdAt: Date?
}

// MARK: - User Preference (Survey)

struct UserPreference: Codable {
    let preferredServices: [String]?
    let preferredCity: String?
    let preferredDistrict: String?
    let preferredStyles: [String]?
    let budgetMin: Double?
    let budgetMax: Double?
}

// MARK: - Commission Tier

struct CommissionTier: Codable, Identifiable {
    let id: String
    let settingId: String?
    let minRevenue: Double?
    let maxRevenue: Double?
    let rate: Double?
}

// MARK: - Salary Config

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

// MARK: - Unit Price Data

struct UnitPriceData: Codable {
    let period: String?
    let averageUnitPrice: Double?
    let count: Int?
}

// MARK: - Time Slot

struct TimeSlot: Codable, Identifiable {
    let id: String
    let staffId: String?
    let date: String?
    let startTime: String?
    let endTime: String?
    let createdAt: Date?
}

// MARK: - Unread Count Response

struct UnreadCountResponse: Codable {
    let count: Int
}

// MARK: - Image Upload Response

struct ImageUploadResponse: Codable {
    let url: String?
    let imageUrl: String?
}

// MARK: - Voucher Liability By Customer

struct VoucherLiabilityByCustomer: Codable, Identifiable {
    let id: String
    let customerId: String?
    let customerName: String?
    let totalSessions: Int?
    let totalBalance: Double?
    let voucherCount: Int?
}
