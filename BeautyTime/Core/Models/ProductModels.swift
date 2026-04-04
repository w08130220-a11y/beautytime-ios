import Foundation

// MARK: - Product

struct Product: Codable, Identifiable {
    let id: String
    let providerId: String?
    let name: String
    let price: Double
    let cost: Double?
    let hasCommission: Bool?
    let commissionRate: Double?     // 0.0-1.0
    let stock: Int?
    let isActive: Bool?
    let createdAt: Date?
}

// MARK: - Product Sale

struct ProductSale: Codable, Identifiable {
    let id: String
    let providerId: String?
    let staffId: String
    let productId: String
    let customerId: String?
    let bookingId: String?
    let quantity: Int
    let unitPrice: Double
    let totalAmount: Double
    let commissionAmount: Double?
    let saleDate: String            // "YYYY-MM-DD"
    let createdAt: Date?
    let product: Product?
    let staff: StaffMember?
}

// MARK: - Service Commission Override
// Per staff×service commission rate, overrides the staff default and provider default.

struct ServiceCommissionOverride: Codable, Identifiable {
    let id: String
    let providerId: String?
    let staffId: String
    let serviceId: String
    let commissionRate: Double      // 0.0-1.0
    let serviceName: String?        // denormalized for display
    let staffName: String?          // denormalized for display
}
