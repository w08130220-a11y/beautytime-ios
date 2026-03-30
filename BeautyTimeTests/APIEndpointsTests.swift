import XCTest
@testable import BeautyTime

final class APIEndpointsTests: XCTestCase {

    // MARK: - Auth Endpoints

    func testAuthEndpoints() {
        XCTAssertEqual(APIEndpoints.Auth.sendOTP, "/api/auth/send-otp")
        XCTAssertEqual(APIEndpoints.Auth.verifyOTP, "/api/auth/verify-otp")
        XCTAssertEqual(APIEndpoints.Auth.checkEmail, "/api/auth/check-email")
        XCTAssertEqual(APIEndpoints.Auth.google, "/api/auth/google")
        XCTAssertEqual(APIEndpoints.Auth.line, "/api/auth/line")
        XCTAssertEqual(APIEndpoints.Auth.apple, "/api/auth/apple")
        XCTAssertEqual(APIEndpoints.Auth.me, "/api/auth/me")
        XCTAssertEqual(APIEndpoints.Auth.phoneSendOTP, "/api/auth/phone/send-otp")
        XCTAssertEqual(APIEndpoints.Auth.phoneVerifyOTP, "/api/auth/phone/verify-otp")
    }

    // MARK: - Provider Endpoints

    func testProviderEndpoints() {
        XCTAssertEqual(APIEndpoints.Providers.list, "/api/providers")
        XCTAssertEqual(APIEndpoints.Providers.detail("abc"), "/api/providers/abc")
        XCTAssertEqual(APIEndpoints.Providers.register, "/api/providers/register")
        XCTAssertEqual(APIEndpoints.Providers.me, "/api/providers/me")
        XCTAssertEqual(APIEndpoints.Providers.popularTags, "/api/providers/popular-tags")
        XCTAssertEqual(APIEndpoints.Providers.myStaffRole, "/api/providers/my-staff-role")
    }

    // MARK: - Service Endpoints

    func testServiceEndpoints() {
        XCTAssertEqual(APIEndpoints.Services.list, "/api/services")
        XCTAssertEqual(APIEndpoints.Services.create, "/api/services")
        XCTAssertEqual(APIEndpoints.Services.update("s1"), "/api/services/s1")
        XCTAssertEqual(APIEndpoints.Services.delete("s1"), "/api/services/s1")
    }

    // MARK: - Staff Endpoints

    func testStaffEndpoints() {
        XCTAssertEqual(APIEndpoints.Staff.list, "/api/staff")
        XCTAssertEqual(APIEndpoints.Staff.create, "/api/staff")
        XCTAssertEqual(APIEndpoints.Staff.update("s1"), "/api/staff/s1")
        XCTAssertEqual(APIEndpoints.Staff.delete("s1"), "/api/staff/s1")
        XCTAssertEqual(APIEndpoints.Staff.invitations, "/api/staff/invitations")
        XCTAssertEqual(APIEndpoints.Staff.myInvitations, "/api/staff/invitations/my")
        XCTAssertEqual(APIEndpoints.Staff.schedulesList, "/api/staff/schedules")
        XCTAssertEqual(APIEndpoints.Staff.schedules("s1"), "/api/staff/s1/schedules")
        XCTAssertEqual(APIEndpoints.Staff.exceptions, "/api/staff/exceptions")
        XCTAssertEqual(APIEndpoints.Staff.deleteException("e1"), "/api/staff/exceptions/e1")
        XCTAssertEqual(APIEndpoints.Staff.timeSlots("s1"), "/api/staff/s1/time-slots")
        XCTAssertEqual(APIEndpoints.Staff.deleteTimeSlot("t1"), "/api/staff/time-slots/t1")
    }

    // MARK: - Booking Endpoints

    func testBookingEndpoints() {
        XCTAssertEqual(APIEndpoints.Bookings.create, "/api/bookings")
        XCTAssertEqual(APIEndpoints.Bookings.my, "/api/bookings/my")
        XCTAssertEqual(APIEndpoints.Bookings.provider("p1"), "/api/bookings/provider/p1")
        XCTAssertEqual(APIEndpoints.Bookings.cancel("b1"), "/api/bookings/b1/cancel")
        XCTAssertEqual(APIEndpoints.Bookings.dispute("b1"), "/api/bookings/b1/dispute")
        XCTAssertEqual(APIEndpoints.Bookings.pay("b1"), "/api/bookings/b1/pay")
    }

    // MARK: - Orders Endpoints

    func testOrdersEndpoints() {
        XCTAssertEqual(APIEndpoints.Orders.list, "/api/orders")
        XCTAssertEqual(APIEndpoints.Orders.updateStatus("o1"), "/api/orders/o1/status")
        XCTAssertEqual(APIEndpoints.Orders.cancel("o1"), "/api/orders/o1/cancel")
    }

    // MARK: - Availability Endpoints

    func testAvailabilityEndpoints() {
        XCTAssertEqual(APIEndpoints.Availability.staff, "/api/availability/staff")
        XCTAssertEqual(APIEndpoints.Availability.staffFind, "/api/availability/staff/find")
        XCTAssertEqual(APIEndpoints.Availability.date, "/api/availability/date")
        XCTAssertEqual(APIEndpoints.Availability.dateBatch, "/api/availability/date/batch")
    }

    // MARK: - Voucher Endpoints

    func testVoucherEndpoints() {
        XCTAssertEqual(APIEndpoints.Vouchers.plans, "/api/vouchers/plans")
        XCTAssertEqual(APIEndpoints.Vouchers.purchase("p1"), "/api/vouchers/purchase/p1")
        XCTAssertEqual(APIEndpoints.Vouchers.my, "/api/vouchers/my")
        XCTAssertEqual(APIEndpoints.Vouchers.generateToken("v1"), "/api/vouchers/v1/generate-token")
        XCTAssertEqual(APIEndpoints.Vouchers.verifyToken, "/api/vouchers/verify-token")
        XCTAssertEqual(APIEndpoints.Vouchers.redeem, "/api/vouchers/redeem")
        XCTAssertEqual(APIEndpoints.Vouchers.cancel("v1"), "/api/vouchers/v1/cancel")
        XCTAssertEqual(APIEndpoints.Vouchers.transactions("v1"), "/api/vouchers/v1/transactions")
        XCTAssertEqual(APIEndpoints.Vouchers.batchCount, "/api/vouchers/transactions/batch")
        XCTAssertEqual(APIEndpoints.Vouchers.sold, "/api/vouchers/sold")
        XCTAssertEqual(APIEndpoints.Vouchers.liability, "/api/vouchers/liability")
    }

    // MARK: - Payroll Endpoints

    func testPayrollEndpoints() {
        XCTAssertEqual(APIEndpoints.Payroll.commission, "/api/payroll/commission")
        XCTAssertEqual(APIEndpoints.Payroll.commissionTiers, "/api/payroll/commission-tiers")
        XCTAssertEqual(APIEndpoints.Payroll.deleteCommissionTier("t1"), "/api/payroll/commission-tiers/t1")
        XCTAssertEqual(APIEndpoints.Payroll.updateCommissionTier("t1"), "/api/payroll/commission-tiers/t1")
        XCTAssertEqual(APIEndpoints.Payroll.salaryConfigs, "/api/payroll/salary-configs")
        XCTAssertEqual(APIEndpoints.Payroll.salaryConfig("s1"), "/api/payroll/salary-configs/s1")
        XCTAssertEqual(APIEndpoints.Payroll.records, "/api/payroll/records")
        XCTAssertEqual(APIEndpoints.Payroll.generate, "/api/payroll/generate")
        XCTAssertEqual(APIEndpoints.Payroll.status, "/api/payroll/status")
    }

    // MARK: - Other Endpoints

    func testNotificationEndpoints() {
        XCTAssertEqual(APIEndpoints.Notifications.list, "/api/notifications")
        XCTAssertEqual(APIEndpoints.Notifications.markRead("n1"), "/api/notifications/n1/read")
        XCTAssertEqual(APIEndpoints.Notifications.delete("n1"), "/api/notifications/n1")
        XCTAssertEqual(APIEndpoints.Notifications.unreadCount, "/api/notifications/unread-count")
        XCTAssertEqual(APIEndpoints.Notifications.readAll, "/api/notifications/read-all")
    }

    func testCustomerEndpoints() {
        XCTAssertEqual(APIEndpoints.Customers.list, "/api/customers")
        XCTAssertEqual(APIEndpoints.Customers.detail("c1"), "/api/customers/c1")
        XCTAssertEqual(APIEndpoints.Customers.addNote("c1"), "/api/customers/c1/notes")
        XCTAssertEqual(APIEndpoints.Customers.deleteNote("n1"), "/api/customers/notes/n1")
    }

    func testMarketingEndpoints() {
        XCTAssertEqual(APIEndpoints.Marketing.templates, "/api/marketing/templates")
        XCTAssertEqual(APIEndpoints.Marketing.save, "/api/marketing/templates")
        XCTAssertEqual(APIEndpoints.Marketing.update("m1"), "/api/marketing/templates/m1")
    }

    func testSettingsEndpoints() {
        XCTAssertEqual(APIEndpoints.Settings.provider, "/api/settings/provider")
        XCTAssertEqual(APIEndpoints.Settings.providerImage, "/api/settings/provider/image")
    }

    func testAnalyticsEndpoints() {
        XCTAssertEqual(APIEndpoints.Analytics.revenue, "/api/analytics/revenue")
        XCTAssertEqual(APIEndpoints.Analytics.serviceRevenue, "/api/analytics/service-revenue")
        XCTAssertEqual(APIEndpoints.Analytics.returnRate, "/api/analytics/return-rate")
        XCTAssertEqual(APIEndpoints.Analytics.unitPrice, "/api/analytics/unit-price")
        XCTAssertEqual(APIEndpoints.Analytics.customerMix, "/api/analytics/customer-mix")
    }

    func testMatchEndpoints() {
        XCTAssertEqual(APIEndpoints.Match.createRequest, "/api/match/requests")
        XCTAssertEqual(APIEndpoints.Match.myRequests, "/api/match/requests/my")
        XCTAssertEqual(APIEndpoints.Match.requestDetail("r1"), "/api/match/requests/r1")
        XCTAssertEqual(APIEndpoints.Match.requestOffers("r1"), "/api/match/requests/r1/offers")
        XCTAssertEqual(APIEndpoints.Match.closeRequest("r1"), "/api/match/requests/r1/close")
    }

    func testPortfolioEndpoints() {
        XCTAssertEqual(APIEndpoints.Portfolio.list, "/api/portfolio")
        XCTAssertEqual(APIEndpoints.Portfolio.create, "/api/portfolio")
        XCTAssertEqual(APIEndpoints.Portfolio.upload, "/api/portfolio/upload")
        XCTAssertEqual(APIEndpoints.Portfolio.update("p1"), "/api/portfolio/p1")
        XCTAssertEqual(APIEndpoints.Portfolio.delete("p1"), "/api/portfolio/p1")
    }
}
