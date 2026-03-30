import XCTest
@testable import BeautyTime

final class FormattersTests: XCTestCase {

    // MARK: - Price Formatting

    func testFormatPriceWithWholeNumber() {
        let result = Formatters.formatPrice(1000)
        XCTAssertTrue(result.contains("1,000"), "Expected formatted price to contain '1,000', got '\(result)'")
    }

    func testFormatPriceWithZero() {
        let result = Formatters.formatPrice(0)
        XCTAssertTrue(result.contains("0"), "Expected formatted price to contain '0', got '\(result)'")
    }

    func testFormatPriceWithLargeNumber() {
        let result = Formatters.formatPrice(100000)
        XCTAssertTrue(result.contains("100,000"), "Expected formatted price to contain '100,000', got '\(result)'")
    }

    func testFormatPriceWithDecimal() {
        let result = Formatters.formatPrice(999.5)
        // Should round to whole number (0 decimal places)
        XCTAssertTrue(result.contains("1,000") || result.contains("999"), "Expected rounded price, got '\(result)'")
    }

    func testPriceShortcut() {
        let result1 = Formatters.formatPrice(500)
        let result2 = Formatters.price(500)
        XCTAssertEqual(result1, result2, "price() should produce same result as formatPrice()")
    }

    // MARK: - Date Formatting

    func testFormatDateWithValidString() {
        let result = Formatters.formatDate("2026-03-15")
        XCTAssertFalse(result.isEmpty, "Should format valid date string")
    }

    func testFormatDateWithInvalidString() {
        let result = Formatters.formatDate("invalid")
        // Should return the original string when parsing fails
        XCTAssertEqual(result, "invalid")
    }

    // MARK: - Display Date

    func testDisplayDate() {
        let date = Date()
        let result = Formatters.displayDate(date)
        XCTAssertFalse(result.isEmpty, "Should format display date")
    }

    // MARK: - Relative Date

    func testRelativeDate() {
        let date = Date()
        let result = Formatters.relativeDate(date)
        XCTAssertFalse(result.isEmpty, "Should format relative date")
    }

    func testRelativeDatePast() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let result = Formatters.relativeDate(pastDate)
        XCTAssertFalse(result.isEmpty, "Should format past relative date")
    }
}
