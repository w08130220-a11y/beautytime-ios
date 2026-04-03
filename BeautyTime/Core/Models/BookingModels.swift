import Foundation

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
        // 容錯：後端 join 可能回傳不完整的物件（缺 id 等必填欄位）
        service = (try? c.decodeIfPresent(Service.self, forKey: .service))
            ?? (try? c.decodeIfPresent(Service.self, forKey: .services))
        provider = (try? c.decodeIfPresent(Provider.self, forKey: .provider))
            ?? (try? c.decodeIfPresent(Provider.self, forKey: .providers))
        staff = (try? c.decodeIfPresent(StaffMember.self, forKey: .staff))
            ?? (try? c.decodeIfPresent(StaffMember.self, forKey: .staffMembers))
    }

    func withStatus(_ newStatus: BookingStatus) -> Booking {
        Booking(
            id: id, customerId: customerId, providerId: providerId,
            serviceId: serviceId, staffId: staffId, date: date, time: time,
            duration: duration, totalPrice: totalPrice, depositAmount: depositAmount,
            depositPaid: depositPaid, status: newStatus, cancellationReason: cancellationReason,
            note: note, createdAt: createdAt, service: service, provider: provider,
            staff: staff, customer: customer
        )
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
    case noShow = "no_show"
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

struct BookingPayResponse: Codable {
    let payment: BookingPaymentDetail?
}

struct BookingPaymentDetail: Codable {
    let merchantTradeNo: String?
    let amount: Double?
    let serviceName: String?
    let bookingId: String?
}

// MARK: - Availability

struct AvailableStaff: Codable {
    let staff: StaffMember
    let availableSlots: [String]?
}

struct AvailableDate: Codable {
    let date: String
    let available: Bool
}

struct StaffFindResponse: Codable {
    let staff: [StaffMember]
    let availableSlots: [String: [StaffTimeSlot]]
}

struct StaffTimeSlot: Codable {
    let time: String
    let available: Bool
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

// MARK: - Time Slot

struct TimeSlot: Codable, Identifiable {
    let id: String
    let staffId: String?
    let date: String?
    let startTime: String?
    let endTime: String?
    let createdAt: Date?
}
