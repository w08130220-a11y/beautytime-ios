import XCTest
@testable import BeautyTime

final class ModelsTests: XCTestCase {

    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoFormatterNoFrac = ISO8601DateFormatter()
        isoFormatterNoFrac.formatOptions = [.withInternetDateTime]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = isoFormatter.date(from: str) { return date }
            if let date = isoFormatterNoFrac.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(str)")
        }
    }

    // MARK: - User

    func testUserDecoding() throws {
        let json = """
        {
            "id": "user-1",
            "email": "test@example.com",
            "full_name": "王小明",
            "role": "customer",
            "preferred_locale": "zh-TW",
            "survey_completed": true
        }
        """.data(using: .utf8)!

        let user = try decoder.decode(User.self, from: json)
        XCTAssertEqual(user.id, "user-1")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.fullName, "王小明")
        XCTAssertEqual(user.role, .customer)
    }

    func testUserRoleDecoding() throws {
        let roles: [(String, UserRole)] = [
            ("\"customer\"", .customer),
            ("\"provider\"", .provider),
            ("\"both\"", .both)
        ]
        for (json, expected) in roles {
            let data = json.data(using: .utf8)!
            let role = try decoder.decode(UserRole.self, from: data)
            XCTAssertEqual(role, expected)
        }
    }

    // MARK: - Provider

    func testProviderDecoding() throws {
        let json = """
        {
            "id": "prov-1",
            "name": "快剪100",
            "category": "hair",
            "city": "台北市",
            "rating": 4.5,
            "review_count": 10,
            "is_verified": true
        }
        """.data(using: .utf8)!

        let provider = try decoder.decode(Provider.self, from: json)
        XCTAssertEqual(provider.id, "prov-1")
        XCTAssertEqual(provider.name, "快剪100")
        XCTAssertEqual(provider.category, .hair)
        XCTAssertEqual(provider.rating, 4.5)
        XCTAssertEqual(provider.isVerified, true)
    }

    // MARK: - Service

    func testServiceDecoding() throws {
        let json = """
        {
            "id": "svc-1",
            "provider_id": "prov-1",
            "name": "韓式剪髮",
            "price": 800,
            "duration": 60,
            "is_available": true,
            "category": "剪髮"
        }
        """.data(using: .utf8)!

        let service = try decoder.decode(Service.self, from: json)
        XCTAssertEqual(service.id, "svc-1")
        XCTAssertEqual(service.name, "韓式剪髮")
        XCTAssertEqual(service.price, 800)
        XCTAssertEqual(service.duration, 60)
        XCTAssertEqual(service.isAvailable, true)
    }

    // MARK: - StaffMember

    func testStaffMemberDecoding() throws {
        let json = """
        {
            "id": "staff-1",
            "provider_id": "prov-1",
            "name": "Amy",
            "title": "資深設計師",
            "role": "designer",
            "specialties": ["美甲", "美睫"],
            "rating": 4.8
        }
        """.data(using: .utf8)!

        let staff = try decoder.decode(StaffMember.self, from: json)
        XCTAssertEqual(staff.id, "staff-1")
        XCTAssertEqual(staff.name, "Amy")
        XCTAssertEqual(staff.role, .designer)
        XCTAssertEqual(staff.specialties, ["美甲", "美睫"])
    }

    func testStaffRoleDecoding() throws {
        let roles: [(String, StaffRole)] = [
            ("\"owner\"", .owner),
            ("\"manager\"", .manager),
            ("\"senior_designer\"", .seniorDesigner),
            ("\"designer\"", .designer),
            ("\"assistant\"", .assistant)
        ]
        for (json, expected) in roles {
            let data = json.data(using: .utf8)!
            let role = try decoder.decode(StaffRole.self, from: data)
            XCTAssertEqual(role, expected)
        }
    }

    // MARK: - BookingStatus

    func testBookingStatusDecoding() throws {
        let statuses: [(String, BookingStatus)] = [
            ("\"pending\"", .pending),
            ("\"confirmed\"", .confirmed),
            ("\"completed\"", .completed),
            ("\"cancelled\"", .cancelled),
            ("\"disputed\"", .disputed)
        ]
        for (json, expected) in statuses {
            let data = json.data(using: .utf8)!
            let status = try decoder.decode(BookingStatus.self, from: data)
            XCTAssertEqual(status, expected)
        }
    }

    // MARK: - VoucherPlan

    func testVoucherPlanDecoding() throws {
        let json = """
        {
            "id": "plan-1",
            "provider_id": "prov-1",
            "type": "session",
            "name": "剪髮10次券",
            "selling_price": 6800,
            "original_price": 8000,
            "sessions_total": 10,
            "valid_days": 180,
            "is_active": true
        }
        """.data(using: .utf8)!

        let plan = try decoder.decode(VoucherPlan.self, from: json)
        XCTAssertEqual(plan.id, "plan-1")
        XCTAssertEqual(plan.name, "剪髮10次券")
        XCTAssertEqual(plan.type, .session)
        XCTAssertEqual(plan.sellingPrice, 6800)
        XCTAssertEqual(plan.sessionsTotal, 10)
    }

    func testVoucherTypeDecoding() throws {
        let types: [(String, VoucherType)] = [
            ("\"session\"", .session),
            ("\"stored_value\"", .storedValue),
            ("\"package\"", .package)
        ]
        for (json, expected) in types {
            let data = json.data(using: .utf8)!
            let t = try decoder.decode(VoucherType.self, from: data)
            XCTAssertEqual(t, expected)
        }
    }

    // MARK: - PaymentStatus

    func testPaymentStatusDecoding() throws {
        let statuses: [(String, PaymentStatus)] = [
            ("\"pending\"", .pending),
            ("\"paid\"", .paid),
            ("\"refunded\"", .refunded),
            ("\"failed\"", .failed)
        ]
        for (json, expected) in statuses {
            let data = json.data(using: .utf8)!
            let status = try decoder.decode(PaymentStatus.self, from: data)
            XCTAssertEqual(status, expected)
        }
    }

    // MARK: - AuthResponse

    func testAuthResponseDecoding() throws {
        let json = """
        {
            "token": "jwt-token-123",
            "user": {
                "id": "user-1",
                "email": "test@example.com",
                "role": "customer"
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(AuthResponse.self, from: json)
        XCTAssertEqual(response.token, "jwt-token-123")
        XCTAssertEqual(response.user?.id, "user-1")
    }

    // MARK: - OTPResponse

    func testOTPResponseDecoding() throws {
        let json = """
        { "message": "驗證碼已發送" }
        """.data(using: .utf8)!

        let response = try decoder.decode(OTPResponse.self, from: json)
        XCTAssertEqual(response.message, "驗證碼已發送")
    }

    // MARK: - BusinessHour

    func testBusinessHourDecoding() throws {
        let json = """
        {
            "id": "bh-1",
            "provider_id": "prov-1",
            "day_of_week": 1,
            "open_time": "09:00",
            "close_time": "18:00",
            "is_open": true
        }
        """.data(using: .utf8)!

        let hour = try decoder.decode(BusinessHour.self, from: json)
        XCTAssertEqual(hour.dayOfWeek, 1)
        XCTAssertEqual(hour.openTime, "09:00")
        XCTAssertEqual(hour.closeTime, "18:00")
        XCTAssertEqual(hour.isOpen, true)
    }

    // MARK: - CommissionSettings

    func testCommissionSettingsDecoding() throws {
        let json = """
        {
            "id": "cs-1",
            "provider_id": "prov-1",
            "salary_model": "base_plus_commission",
            "default_commission_rate": 0.5,
            "commission_type": "tiered",
            "product_commission_rate": 0.1
        }
        """.data(using: .utf8)!

        let settings = try decoder.decode(CommissionSettings.self, from: json)
        XCTAssertEqual(settings.id, "cs-1")
        XCTAssertEqual(settings.defaultCommissionRate, 0.5)
        XCTAssertEqual(settings.commissionType, .tiered)
        XCTAssertEqual(settings.productCommissionRate, 0.1)
    }

    // MARK: - MarketingTemplate

    func testMarketingTemplateDecoding() throws {
        let json = """
        {
            "id": "mt-1",
            "provider_id": "prov-1",
            "type": "birthday",
            "message": "生日快樂！",
            "enabled": true
        }
        """.data(using: .utf8)!

        let template = try decoder.decode(MarketingTemplate.self, from: json)
        XCTAssertEqual(template.id, "mt-1")
        XCTAssertEqual(template.type, "birthday")
        XCTAssertEqual(template.message, "生日快樂！")
        XCTAssertEqual(template.enabled, true)
        XCTAssertEqual(template.displayMessage, "生日快樂！")
        XCTAssertTrue(template.isEnabled)
    }

    func testMarketingTemplateComputedProperties() throws {
        // Test with content field instead of message
        let json = """
        {
            "id": "mt-2",
            "type": "promotion",
            "content": "促銷活動",
            "is_active": false
        }
        """.data(using: .utf8)!

        let template = try decoder.decode(MarketingTemplate.self, from: json)
        XCTAssertEqual(template.displayMessage, "促銷活動")
        XCTAssertFalse(template.isEnabled)
    }

    // MARK: - MatchRequest

    func testMatchStatusDecoding() throws {
        let statuses: [(String, MatchStatus)] = [
            ("\"open\"", .open),
            ("\"matched\"", .matched),
            ("\"closed\"", .closed)
        ]
        for (json, expected) in statuses {
            let data = json.data(using: .utf8)!
            let status = try decoder.decode(MatchStatus.self, from: data)
            XCTAssertEqual(status, expected)
        }
    }

    // MARK: - VoucherPurchaseResponse

    func testVoucherPurchaseResponseDecoding() throws {
        let json = """
        {
            "voucher": {
                "id": "v-1",
                "status": "pending"
            },
            "payment": {
                "transaction_id": "tx-1",
                "amount": 6800
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(VoucherPurchaseResponse.self, from: json)
        XCTAssertEqual(response.voucher?.id, "v-1")
        XCTAssertNotNil(response.payment)
        XCTAssertEqual(response.payment?.amount, 6800)
    }

    func testVoucherPurchaseResponseWithoutPayment() throws {
        let json = """
        {
            "voucher": {
                "id": "v-2",
                "status": "active"
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(VoucherPurchaseResponse.self, from: json)
        XCTAssertNotNil(response.voucher)
        XCTAssertNil(response.payment)
    }

    // MARK: - PaymentResponse

    func testPaymentResponseDecoding() throws {
        let json = """
        {
            "html": "<form>...</form>",
            "merchant_trade_no": "MT123456"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PaymentResponse.self, from: json)
        XCTAssertEqual(response.html, "<form>...</form>")
        XCTAssertEqual(response.merchantTradeNo, "MT123456")
    }

    // MARK: - DashboardStats

    func testDashboardStatsDecoding() throws {
        let json = """
        {
            "today_revenue": 5000,
            "today_bookings": 3,
            "pending_bookings": 1,
            "total_customers": 3,
            "monthly_revenue": 150000,
            "monthly_bookings": 45
        }
        """.data(using: .utf8)!

        let stats = try decoder.decode(DashboardStats.self, from: json)
        XCTAssertEqual(stats.todayRevenue, 5000)
        XCTAssertEqual(stats.todayBookings, 3)
        XCTAssertEqual(stats.monthlyRevenue, 150000)
    }

    // MARK: - AppNotification

    func testAppNotificationDecoding() throws {
        let json = """
        {
            "id": "notif-1",
            "title": "新預約",
            "body": "您有一個新預約",
            "is_read": false,
            "created_at": "2026-03-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let notification = try decoder.decode(AppNotification.self, from: json)
        XCTAssertEqual(notification.id, "notif-1")
        XCTAssertEqual(notification.title, "新預約")
        XCTAssertEqual(notification.isRead, false)
    }

    // MARK: - SalaryConfig

    func testSalaryConfigDecoding() throws {
        let json = """
        {
            "id": "sc-1",
            "staff_id": "staff-1",
            "provider_id": "prov-1",
            "base_salary": 30000,
            "transportation_allowance": 2000,
            "meal_allowance": 1500,
            "other_allowance": 500,
            "use_custom_commission": true,
            "custom_commission_rate": 40,
            "designation_bonus": 500
        }
        """.data(using: .utf8)!

        let config = try decoder.decode(SalaryConfig.self, from: json)
        XCTAssertEqual(config.staffId, "staff-1")
        XCTAssertEqual(config.baseSalary, 30000)
        XCTAssertEqual(config.designationBonus, 500)
    }

    // MARK: - CommissionTier

    func testCommissionTierDecoding() throws {
        let json = """
        {
            "id": "tier-1",
            "setting_id": "cs-1",
            "min_revenue": 0,
            "max_revenue": 50000,
            "rate": 40,
            "sort_order": 1
        }
        """.data(using: .utf8)!

        let tier = try decoder.decode(CommissionTier.self, from: json)
        XCTAssertEqual(tier.id, "tier-1")
        XCTAssertEqual(tier.minRevenue, 0)
        XCTAssertEqual(tier.maxRevenue, 50000)
        XCTAssertEqual(tier.rate, 40)
    }

    func testCommissionTierWithNullMaxRevenue() throws {
        let json = """
        {
            "id": "tier-2",
            "setting_id": "cs-1",
            "min_revenue": 50001,
            "max_revenue": null,
            "rate": 50,
            "sort_order": 2
        }
        """.data(using: .utf8)!

        let tier = try decoder.decode(CommissionTier.self, from: json)
        XCTAssertNil(tier.maxRevenue)
        XCTAssertEqual(tier.rate, 50)
    }

    // MARK: - Review

    func testReviewDecoding() throws {
        let json = """
        {
            "id": "rev-1",
            "booking_id": "b-1",
            "customer_id": "c-1",
            "provider_id": "prov-1",
            "rating": 5,
            "comment": "服務很好！"
        }
        """.data(using: .utf8)!

        let review = try decoder.decode(Review.self, from: json)
        XCTAssertEqual(review.id, "rev-1")
        XCTAssertEqual(review.rating, 5)
        XCTAssertEqual(review.comment, "服務很好！")
    }

    // MARK: - PortfolioItem

    func testPortfolioItemDecoding() throws {
        let json = """
        {
            "id": "port-1",
            "provider_id": "prov-1",
            "after_photo_url": "https://example.com/after.jpg",
            "before_photo_url": "https://example.com/before.jpg",
            "description": "韓式燙髮",
            "style_tags": ["燙髮", "韓式"]
        }
        """.data(using: .utf8)!

        let item = try decoder.decode(PortfolioItem.self, from: json)
        XCTAssertEqual(item.id, "port-1")
        XCTAssertEqual(item.styleTags, ["燙髮", "韓式"])
    }
}
