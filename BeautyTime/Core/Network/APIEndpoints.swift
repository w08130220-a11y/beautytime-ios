import Foundation

enum APIEndpoints {

    // MARK: - Auth

    enum Auth {
        static let sendOTP = "/api/auth/send-otp"
        static let verifyOTP = "/api/auth/verify-otp"
        static let checkEmail = "/api/auth/check-email"
        static let google = "/api/auth/google"
        static let line = "/api/auth/line"
        static let apple = "/api/auth/apple"
        static let me = "/api/auth/me"
        static let phoneSendOTP = "/api/auth/phone/send-otp"
        static let phoneVerifyOTP = "/api/auth/phone/verify-otp"
    }

    // MARK: - Providers

    enum Providers {
        static let list = "/api/providers"
        static func detail(_ id: String) -> String { "/api/providers/\(id)" }
        static let register = "/api/providers/register"
        static func update(_ id: String) -> String { "/api/providers/\(id)" }
        static let me = "/api/providers/me"
        static let popularTags = "/api/providers/popular-tags"
        static let myStaffRole = "/api/providers/my-staff-role"
    }

    // MARK: - Services

    enum Services {
        static let list = "/api/services"
        static let create = "/api/services"
        static func update(_ id: String) -> String { "/api/services/\(id)" }
        static func delete(_ id: String) -> String { "/api/services/\(id)" }
    }

    // MARK: - Staff

    enum Staff {
        static let list = "/api/staff"
        static let create = "/api/staff"
        static func update(_ id: String) -> String { "/api/staff/\(id)" }
        static func delete(_ id: String) -> String { "/api/staff/\(id)" }
        static let invitations = "/api/staff/invitations"
        static let myInvitations = "/api/staff/invitations/my"
        static func staffInvitations(_ staffId: String) -> String { "/api/staff/invitations/staff/\(staffId)" }
        static let invitationsBatch = "/api/staff/invitations/batch"
        static func acceptInvitation(_ id: String) -> String { "/api/staff/invitations/\(id)" }
        static func deleteInvitation(_ id: String) -> String { "/api/staff/invitations/\(id)" }
        static let schedulesList = "/api/staff/schedules"
        static func schedules(_ staffId: String) -> String { "/api/staff/\(staffId)/schedules" }
        static let exceptions = "/api/staff/exceptions"
        static func deleteException(_ id: String) -> String { "/api/staff/exceptions/\(id)" }
        static func timeSlots(_ staffId: String) -> String { "/api/staff/\(staffId)/time-slots" }
        static func deleteTimeSlot(_ id: String) -> String { "/api/staff/time-slots/\(id)" }
    }

    // MARK: - Bookings

    enum Bookings {
        static let create = "/api/bookings"
        static let my = "/api/bookings/my"
        static func provider(_ providerId: String) -> String { "/api/bookings/provider/\(providerId)" }
        static func cancel(_ id: String) -> String { "/api/bookings/\(id)/cancel" }
        static func status(_ id: String) -> String { "/api/bookings/\(id)/status" }
        static func dispute(_ id: String) -> String { "/api/bookings/\(id)/dispute" }
        static func pay(_ id: String) -> String { "/api/bookings/\(id)/pay" }
    }

    // MARK: - Availability

    enum Availability {
        static let staff = "/api/availability/staff"
        static let staffFind = "/api/availability/staff/find"
        static let date = "/api/availability/date"
        static let dateBatch = "/api/availability/date/batch"
    }

    // MARK: - Payments

    enum Payments {
        static let create = "/api/payments"
        static let result = "/api/payments/result"
        static let callback = "/api/payments/callback"
    }

    // MARK: - Vouchers

    enum Vouchers {
        static let plans = "/api/vouchers/plans"
        static let createPlan = "/api/vouchers/plans"
        static func updatePlan(_ id: String) -> String { "/api/vouchers/plans/\(id)" }
        static func deletePlan(_ id: String) -> String { "/api/vouchers/plans/\(id)" }
        static func purchase(_ planId: String) -> String { "/api/vouchers/purchase/\(planId)" }
        static let my = "/api/vouchers/my"
        static let provider = "/api/vouchers/provider"
        static func generateToken(_ id: String) -> String { "/api/vouchers/\(id)/generate-token" }
        static let verifyToken = "/api/vouchers/verify-token"
        static let redeem = "/api/vouchers/redeem"
        static func cancel(_ id: String) -> String { "/api/vouchers/\(id)/cancel" }
        static func transactions(_ id: String) -> String { "/api/vouchers/\(id)/transactions" }
        static let batchCount = "/api/vouchers/transactions/batch"
        static let sold = "/api/vouchers/sold"
        static let liability = "/api/vouchers/liability"
        static let liabilityByCustomer = "/api/vouchers/liability-by-customer"
    }

    // MARK: - Reviews

    enum Reviews {
        static let list = "/api/reviews"
        static let create = "/api/reviews"
    }

    // MARK: - Favorites

    enum Favorites {
        static let toggle = "/api/favorites/toggle"
        static let list = "/api/favorites"
        static let check = "/api/favorites/check"
    }

    // MARK: - Match

    enum Match {
        static let createRequest = "/api/match/requests"
        static let myRequests = "/api/match/requests/my"
        static func requestDetail(_ id: String) -> String { "/api/match/requests/\(id)" }
        static func requestOffers(_ id: String) -> String { "/api/match/requests/\(id)/offers" }
        static func closeRequest(_ id: String) -> String { "/api/match/requests/\(id)/close" }
        static let available = "/api/match/requests/available"
        static let createOffer = "/api/match/offers"
        static func acceptOffer(_ id: String) -> String { "/api/match/offers/\(id)/accept" }
        static func rejectOffer(_ id: String) -> String { "/api/match/offers/\(id)/reject" }
    }

    // MARK: - Portfolio

    enum Portfolio {
        static let list = "/api/portfolio"
        static let create = "/api/portfolio"
        static let upload = "/api/portfolio/upload"
        static func update(_ id: String) -> String { "/api/portfolio/\(id)" }
        static func delete(_ id: String) -> String { "/api/portfolio/\(id)" }
    }

    // MARK: - Analytics

    enum Analytics {
        static let revenue = "/api/analytics/revenue"
        static let serviceRevenue = "/api/analytics/service-revenue"
        static let returnRate = "/api/analytics/return-rate"
        static let unitPrice = "/api/analytics/unit-price"
        static let customerMix = "/api/analytics/customer-mix"
    }

    // MARK: - Hours

    enum Hours {
        static let get = "/api/hours"
        static let update = "/api/hours"
    }

    // MARK: - Notifications

    enum Notifications {
        static let list = "/api/notifications"
        static func markRead(_ id: String) -> String { "/api/notifications/\(id)/read" }
        static func delete(_ id: String) -> String { "/api/notifications/\(id)" }
        static let unreadCount = "/api/notifications/unread-count"
        static let readAll = "/api/notifications/read-all"
    }

    // MARK: - Customers

    enum Customers {
        static let list = "/api/customers"
        static func detail(_ id: String) -> String { "/api/customers/\(id)" }
        static func addNote(_ customerId: String) -> String { "/api/customers/\(customerId)/notes" }
        static func deleteNote(_ noteId: String) -> String { "/api/customers/notes/\(noteId)" }
    }

    // MARK: - Coupons

    enum Coupons {
        static let verify = "/api/coupons/verify"
    }

    // MARK: - Payroll & Commission

    enum Payroll {
        static let commission = "/api/payroll/commission"
        static let commissionTiers = "/api/payroll/commission-tiers"
        static func deleteCommissionTier(_ id: String) -> String { "/api/payroll/commission-tiers/\(id)" }
        static func updateCommissionTier(_ id: String) -> String { "/api/payroll/commission-tiers/\(id)" }
        static let salaryConfigs = "/api/payroll/salary-configs"
        static func salaryConfig(_ staffId: String) -> String { "/api/payroll/salary-configs/\(staffId)" }
        static let records = "/api/payroll/records"
        static let generate = "/api/payroll/generate"
        static let status = "/api/payroll/status"
    }

    // MARK: - Announcements

    enum Announcements {
        static let published = "/api/announcements/published"
    }

    // MARK: - Stats

    enum Stats {
        static let dashboard = "/api/stats/dashboard"
        static let staffPerformance = "/api/stats/staff-performance"
    }

    // MARK: - Users

    enum Users {
        static let me = "/api/users/me"
        static let avatar = "/api/users/me/avatar"
        static let myVouchers = "/api/users/me/vouchers"
        static let myFavorites = "/api/users/me/favorites"
        static let search = "/api/users/search"
    }

    // MARK: - Survey

    enum Survey {
        static let save = "/api/survey"
        static let preferences = "/api/survey/preferences"
        static let browseHistory = "/api/survey/browse-history"
        static let searchHistory = "/api/survey/search-history"
    }

    // MARK: - Settings

    enum Settings {
        static let provider = "/api/settings/provider"
        static let providerImage = "/api/settings/provider/image"
    }

    // MARK: - Orders (商家訂單管理)

    enum Orders {
        static let list = "/api/orders"
        static func updateStatus(_ id: String) -> String { "/api/orders/\(id)/status" }
        static func cancel(_ id: String) -> String { "/api/orders/\(id)/cancel" }
    }

    // MARK: - Marketing

    enum Marketing {
        static let templates = "/api/marketing/templates"
        static let save = "/api/marketing/templates"
        static func update(_ id: String) -> String { "/api/marketing/templates/\(id)" }
    }
}
