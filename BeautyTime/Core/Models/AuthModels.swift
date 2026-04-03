import Foundation

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

struct UnreadCountResponse: Codable {
    let count: Int
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

// MARK: - Announcement

struct Announcement: Codable, Identifiable {
    let id: String
    let title: String?
    let content: String?
    let type: String?
    let isActive: Bool?
    let createdAt: Date?
}
