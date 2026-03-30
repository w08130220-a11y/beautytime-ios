import XCTest
import SwiftUI
@testable import BeautyTime

final class ConstantsTests: XCTestCase {

    // MARK: - ServiceCategory

    func testServiceCategoryAllCases() {
        let cases = ServiceCategory.allCases
        XCTAssertEqual(cases.count, 7, "Should have 7 service categories")
        XCTAssertTrue(cases.contains(.nail))
        XCTAssertTrue(cases.contains(.lash))
        XCTAssertTrue(cases.contains(.nailLash))
        XCTAssertTrue(cases.contains(.hair))
        XCTAssertTrue(cases.contains(.spa))
        XCTAssertTrue(cases.contains(.beauty))
        XCTAssertTrue(cases.contains(.tattoo))
    }

    func testServiceCategoryDisplayNames() {
        XCTAssertFalse(ServiceCategory.nail.displayName.isEmpty)
        XCTAssertFalse(ServiceCategory.hair.displayName.isEmpty)
        XCTAssertFalse(ServiceCategory.spa.displayName.isEmpty)
    }

    func testServiceCategoryIconNames() {
        for category in ServiceCategory.allCases {
            XCTAssertFalse(category.iconName.isEmpty, "\(category) should have an icon name")
        }
    }

    // MARK: - TaiwanCity

    func testTaiwanCityAllCases() {
        let cities = TaiwanCity.allCases
        XCTAssertEqual(cities.count, 22, "Taiwan has 22 administrative divisions")
    }

    func testTaiwanCityDisplayNames() {
        XCTAssertFalse(TaiwanCity.taipei.displayName.isEmpty)
        XCTAssertFalse(TaiwanCity.kaohsiung.displayName.isEmpty)
    }

    // MARK: - BookingStatus Extensions

    func testBookingStatusDisplayNames() {
        XCTAssertFalse(BookingStatus.pending.displayName.isEmpty)
        XCTAssertFalse(BookingStatus.confirmed.displayName.isEmpty)
        XCTAssertFalse(BookingStatus.completed.displayName.isEmpty)
        XCTAssertFalse(BookingStatus.cancelled.displayName.isEmpty)
    }

    func testBookingStatusColors() {
        // Just verify they don't crash
        _ = BookingStatus.pending.color
        _ = BookingStatus.confirmed.color
        _ = BookingStatus.completed.color
        _ = BookingStatus.cancelled.color
    }

    // MARK: - VoucherType Extensions

    func testVoucherTypeDisplayNames() {
        XCTAssertFalse(VoucherType.session.displayName.isEmpty)
        XCTAssertFalse(VoucherType.storedValue.displayName.isEmpty)
        XCTAssertFalse(VoucherType.package.displayName.isEmpty)
    }

    // MARK: - StaffRole Extensions

    func testStaffRoleDisplayNames() {
        XCTAssertFalse(StaffRole.owner.displayName.isEmpty)
        XCTAssertFalse(StaffRole.manager.displayName.isEmpty)
        XCTAssertFalse(StaffRole.designer.displayName.isEmpty)
    }

    // MARK: - Staff Permissions

    func testStaffPagePermissions() {
        let ownerPerms = staffPagePermissions[.owner]
        XCTAssertNotNil(ownerPerms, "Owner should have permissions defined")
        XCTAssertTrue(ownerPerms?.isEmpty == false, "Owner should have some permissions")
    }
}
