import Foundation

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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        providerId = try c.decode(String.self, forKey: .providerId)
        userId = try c.decodeIfPresent(String.self, forKey: .userId)
        // 容錯：後端回傳未知 role 時不讓整個解碼失敗
        role = try? c.decodeIfPresent(StaffRole.self, forKey: .role)
        name = try c.decode(String.self, forKey: .name)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        photoUrl = try c.decodeIfPresent(String.self, forKey: .photoUrl)
        specialties = try c.decodeIfPresent([String].self, forKey: .specialties)
        rating = try c.decodeIfPresent(Double.self, forKey: .rating)
        reviewCount = try c.decodeIfPresent(Int.self, forKey: .reviewCount)
        isActive = try c.decodeIfPresent(Bool.self, forKey: .isActive)
    }
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

// MARK: - Popular Tag

struct PopularTag: Codable {
    let tag: String
    let count: Int
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

// MARK: - API Response Wrappers

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
    let hours: [BusinessHour]?
    let voucherPlans: [VoucherPlan]?

    var allHours: [BusinessHour] {
        businessHours ?? hours ?? []
    }
}

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
    let isWorking: Bool?

    var isAvailable: Bool? { isWorking }
}

// MARK: - Staff Exception

struct StaffException: Codable, Identifiable {
    let id: String
    let staffId: String?
    let date: String?
    let type: String?
    let note: String?
    let startTime: String?
    let endTime: String?
    let reason: String?
    let isBlocked: Bool?
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

// MARK: - Image Upload Response

struct ImageUploadResponse: Codable {
    let url: String?
    let imageUrl: String?
}

// MARK: - Marketing Template

struct MarketingTemplate: Codable, Identifiable {
    let id: String
    let providerId: String?
    let name: String?
    let content: String?
    let message: String?
    let type: String?
    let isActive: Bool?
    let enabled: Bool?
    let createdAt: Date?

    var displayMessage: String {
        message ?? content ?? ""
    }

    var isEnabled: Bool {
        enabled ?? isActive ?? true
    }

    var typeName: String {
        switch type {
        case "birthday": return "生日祝福"
        case "revisit": return "回訪提醒"
        case "promotion": return "促銷活動"
        default: return type ?? "未分類"
        }
    }
}
