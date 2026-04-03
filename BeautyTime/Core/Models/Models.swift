import Foundation
import SwiftUI

// Models have been split into focused files:
// - AuthModels.swift      (User, Auth responses, Notifications, Preferences)
// - ProviderModels.swift   (Provider, Staff, Service, Review, Portfolio, Favorites)
// - BookingModels.swift    (Booking, Payment, Availability, Match, Coupon)
// - ManageModels.swift     (Dashboard, Analytics, Payroll, Customer, Voucher)
//
// This file is kept as a ServiceCategory enum that is shared across multiple model files.

// MARK: - Shared Enums

enum ServiceCategory: String, Codable, CaseIterable {
    case nail = "nail"
    case eyelash = "eyelash"
    case hair = "hair"
    case spa = "spa"
    case tattoo = "tattoo"
    case microblading = "microblading"
    case skincare = "skincare"
    case other = "other"

    var displayName: String {
        switch self {
        case .nail: return "美甲"
        case .eyelash: return "美睫"
        case .hair: return "美髮"
        case .spa: return "SPA"
        case .tattoo: return "紋繡"
        case .microblading: return "霧眉"
        case .skincare: return "護膚"
        case .other: return "其他"
        }
    }
}
