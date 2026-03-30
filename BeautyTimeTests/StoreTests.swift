import XCTest
@testable import BeautyTime

// MARK: - AuthStore Tests

final class AuthStoreTests: XCTestCase {

    func testInitialState() {
        let store = AuthStore()
        XCTAssertFalse(store.isAuthenticated)
        XCTAssertNil(store.currentUser)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertFalse(store.otpSent)
        XCTAssertTrue(store.otpEmail.isEmpty)
    }

    func testSignOutClearsState() {
        let store = AuthStore()
        store.isAuthenticated = true
        store.otpSent = true
        store.otpEmail = "test@test.com"

        store.signOut()

        XCTAssertFalse(store.isAuthenticated)
        XCTAssertNil(store.currentUser)
        XCTAssertFalse(store.otpSent)
    }
}

// MARK: - UserStore Tests

final class UserStoreTests: XCTestCase {

    func testInitialState() {
        let store = UserStore()
        XCTAssertNil(store.currentUser)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testClearUser() {
        let store = UserStore()
        store.clearUser()
        XCTAssertNil(store.currentUser)
    }
}

// MARK: - ProviderStore Tests

final class ProviderStoreTests: XCTestCase {

    func testInitialState() {
        let store = ProviderStore()
        XCTAssertTrue(store.providers.isEmpty)
        XCTAssertTrue(store.searchQuery.isEmpty)
        XCTAssertNil(store.selectedCategory)
        XCTAssertNil(store.selectedCity)
        XCTAssertEqual(store.currentPage, 1)
        XCTAssertTrue(store.hasMore)
        XCTAssertTrue(store.favorites.isEmpty)
        XCTAssertTrue(store.favoriteProviderIds.isEmpty)
    }

    func testIsFavoriteWithEmptySet() {
        let store = ProviderStore()
        XCTAssertFalse(store.isFavorite("prov-1"))
    }

    func testIsFavoriteWithMatchingId() {
        let store = ProviderStore()
        store.favoriteProviderIds = Set(["prov-1", "prov-2"])
        XCTAssertTrue(store.isFavorite("prov-1"))
        XCTAssertFalse(store.isFavorite("prov-3"))
    }
}

// MARK: - BookingFlowStore Tests

final class BookingFlowStoreTests: XCTestCase {

    func testInitialState() {
        let store = BookingFlowStore()
        XCTAssertEqual(store.currentStep, .selectService)
        XCTAssertTrue(store.providerId.isEmpty)
        XCTAssertNil(store.selectedService)
        XCTAssertNil(store.selectedStaff)
        XCTAssertNil(store.selectedDate)
        XCTAssertNil(store.selectedTime)
        XCTAssertTrue(store.note.isEmpty)
    }

    func testNextStep() {
        let store = BookingFlowStore()
        XCTAssertEqual(store.currentStep, .selectService)
        store.nextStep()
        XCTAssertEqual(store.currentStep, .selectDateTime)
        store.nextStep()
        XCTAssertEqual(store.currentStep, .selectStaff)
        store.nextStep()
        XCTAssertEqual(store.currentStep, .confirm)
        store.nextStep()
        XCTAssertEqual(store.currentStep, .payment)
    }

    func testPreviousStep() {
        let store = BookingFlowStore()
        store.currentStep = .confirm
        store.previousStep()
        XCTAssertEqual(store.currentStep, .selectStaff)
        store.previousStep()
        XCTAssertEqual(store.currentStep, .selectDateTime)
    }

    func testReset() {
        let store = BookingFlowStore()
        store.currentStep = .payment
        store.providerId = "test"
        store.note = "some note"
        store.reset()
        XCTAssertEqual(store.currentStep, .selectService)
        XCTAssertTrue(store.note.isEmpty)
        XCTAssertNil(store.selectedService)
    }

    func testTotalPriceWithNoService() {
        let store = BookingFlowStore()
        XCTAssertEqual(store.totalPrice, 0)
    }
}

// MARK: - ManageStore Tests

final class ManageStoreTests: XCTestCase {

    func testInitialState() {
        let store = ManageStore()
        XCTAssertTrue(store.providerId.isEmpty)
        XCTAssertNil(store.revenueData)
        XCTAssertTrue(store.todayBookings.isEmpty)
        XCTAssertTrue(store.services.isEmpty)
        XCTAssertTrue(store.orders.isEmpty)
        XCTAssertTrue(store.customers.isEmpty)
        XCTAssertTrue(store.portfolio.isEmpty)
        XCTAssertTrue(store.businessHours.isEmpty)
        XCTAssertTrue(store.marketingTemplates.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testOrderFilterInitialState() {
        let store = ManageStore()
        XCTAssertNil(store.orderFilter)
    }
}

// MARK: - PayrollManageStore Tests

final class PayrollManageStoreTests: XCTestCase {

    func testInitialState() {
        let store = PayrollManageStore()
        XCTAssertTrue(store.providerId.isEmpty)
        XCTAssertNil(store.commissionSettings)
        XCTAssertTrue(store.payrollRecords.isEmpty)
        XCTAssertTrue(store.commissionTiers.isEmpty)
        XCTAssertTrue(store.salaryConfigs.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testLoadCommissionSettingsGuardsEmptyProviderId() async {
        let store = PayrollManageStore()
        store.providerId = ""
        await store.loadCommissionSettings()
        // Should return early without error
        XCTAssertNil(store.error)
        XCTAssertNil(store.commissionSettings)
    }

    func testLoadPayrollGuardsEmptyProviderId() async {
        let store = PayrollManageStore()
        store.providerId = ""
        await store.loadPayroll(month: 3, year: 2026)
        XCTAssertNil(store.error)
        XCTAssertTrue(store.payrollRecords.isEmpty)
    }

    func testCalculatePayrollGuardsEmptyProviderId() async {
        let store = PayrollManageStore()
        store.providerId = ""
        await store.calculatePayroll(month: 3, year: 2026)
        XCTAssertNotNil(store.error)
    }

    func testLoadCommissionTiersGuardsNoSettingId() async {
        let store = PayrollManageStore()
        store.commissionSettings = nil
        await store.loadCommissionTiers()
        // Should return early
        XCTAssertTrue(store.commissionTiers.isEmpty)
    }
}

// MARK: - StaffManageStore Tests

final class StaffManageStoreTests: XCTestCase {

    func testInitialState() {
        let store = StaffManageStore()
        XCTAssertTrue(store.providerId.isEmpty)
        XCTAssertTrue(store.staff.isEmpty)
        XCTAssertTrue(store.staffSchedules.isEmpty)
        XCTAssertTrue(store.staffExceptions.isEmpty)
        XCTAssertTrue(store.timeSlots.isEmpty)
        XCTAssertTrue(store.staffInvitations.isEmpty)
        XCTAssertTrue(store.staffPerformance.isEmpty)
    }
}

// MARK: - VoucherManageStore Tests

final class VoucherManageStoreTests: XCTestCase {

    func testInitialState() {
        let store = VoucherManageStore()
        XCTAssertTrue(store.providerId.isEmpty)
        XCTAssertTrue(store.voucherPlans.isEmpty)
        XCTAssertTrue(store.soldVouchers.isEmpty)
        XCTAssertNil(store.voucherLiability)
        XCTAssertTrue(store.liabilityByCustomer.isEmpty)
    }
}

// MARK: - AnalyticsManageStore Tests

final class AnalyticsManageStoreTests: XCTestCase {

    func testInitialState() {
        let store = AnalyticsManageStore()
        XCTAssertTrue(store.providerId.isEmpty)
        XCTAssertNil(store.revenueData)
        XCTAssertTrue(store.serviceRevenue.isEmpty)
        XCTAssertNil(store.returnRate)
        XCTAssertNil(store.customerMix)
        XCTAssertTrue(store.unitPriceData.isEmpty)
    }
}

// MARK: - NotificationStore Tests

final class NotificationStoreTests: XCTestCase {

    func testInitialState() {
        let store = NotificationStore()
        XCTAssertTrue(store.notifications.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testUnreadCountWithEmptyNotifications() {
        let store = NotificationStore()
        XCTAssertEqual(store.unreadCount, 0)
    }
}
