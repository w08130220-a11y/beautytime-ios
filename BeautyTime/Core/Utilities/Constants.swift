import Foundation
import SwiftUI

// MARK: - Service Category

enum ServiceCategory: String, Codable, CaseIterable {
    case nail = "nail"
    case lash = "lash"
    case nailLash = "nail_lash"
    case hair = "hair"
    case spa = "spa"
    case beauty = "beauty"
    case tattoo = "tattoo"

    var displayName: String {
        switch self {
        case .nail: return String(localized: "美甲")
        case .lash: return String(localized: "美睫")
        case .nailLash: return String(localized: "美甲美睫")
        case .hair: return String(localized: "美髮")
        case .spa: return String(localized: "SPA")
        case .beauty: return String(localized: "美容")
        case .tattoo: return String(localized: "紋繡")
        }
    }

    var iconName: String {
        switch self {
        case .nail: return "hand.raised.fill"
        case .lash: return "eye.fill"
        case .nailLash: return "sparkles"
        case .hair: return "scissors"
        case .spa: return "leaf.fill"
        case .beauty: return "face.smiling.fill"
        case .tattoo: return "pencil.tip"
        }
    }
}

// MARK: - Taiwan City

enum TaiwanCity: String, Codable, CaseIterable {
    case taipei = "taipei"
    case newTaipei = "new_taipei"
    case taoyuan = "taoyuan"
    case taichung = "taichung"
    case tainan = "tainan"
    case kaohsiung = "kaohsiung"
    case keelung = "keelung"
    case hsinchu = "hsinchu"
    case hsinchuCounty = "hsinchu_county"
    case miaoli = "miaoli"
    case changhua = "changhua"
    case nantou = "nantou"
    case yunlin = "yunlin"
    case chiayi = "chiayi"
    case chiayiCounty = "chiayi_county"
    case pingtung = "pingtung"
    case yilan = "yilan"
    case hualien = "hualien"
    case taitung = "taitung"
    case penghu = "penghu"
    case kinmen = "kinmen"
    case lienchiang = "lienchiang"

    var displayName: String {
        switch self {
        case .taipei: return "台北市"
        case .newTaipei: return "新北市"
        case .taoyuan: return "桃園市"
        case .taichung: return "台中市"
        case .tainan: return "台南市"
        case .kaohsiung: return "高雄市"
        case .keelung: return "基隆市"
        case .hsinchu: return "新竹市"
        case .hsinchuCounty: return "新竹縣"
        case .miaoli: return "苗栗縣"
        case .changhua: return "彰化縣"
        case .nantou: return "南投縣"
        case .yunlin: return "雲林縣"
        case .chiayi: return "嘉義市"
        case .chiayiCounty: return "嘉義縣"
        case .pingtung: return "屏東縣"
        case .yilan: return "宜蘭縣"
        case .hualien: return "花蓮縣"
        case .taitung: return "台東縣"
        case .penghu: return "澎湖縣"
        case .kinmen: return "金門縣"
        case .lienchiang: return "連江縣"
        }
    }
}

// MARK: - Booking Status Extensions

extension BookingStatus {
    var color: Color {
        switch self {
        case .pending: return .orange
        case .confirmed: return .blue
        case .completed: return .green
        case .cancelled: return .gray
        case .disputed: return .red
        }
    }

    var displayName: String {
        switch self {
        case .pending: return "待確認"
        case .confirmed: return "已確認"
        case .completed: return "已完成"
        case .cancelled: return "已取消"
        case .disputed: return "爭議中"
        }
    }
}

// MARK: - Payment Status Extensions

extension PaymentStatus {
    var color: Color {
        switch self {
        case .pending: return .orange
        case .paid: return .green
        case .refunded: return .blue
        case .failed: return .red
        }
    }

    var displayName: String {
        switch self {
        case .pending: return "待付款"
        case .paid: return "已付款"
        case .refunded: return "已退款"
        case .failed: return "付款失敗"
        }
    }
}

// MARK: - Voucher Status Extensions

extension VoucherStatus {
    var color: Color {
        switch self {
        case .pending: return .orange
        case .active: return .green
        case .frozen: return .blue
        case .expired: return .gray
        case .refunded: return .orange
        }
    }

    var displayName: String {
        switch self {
        case .pending: return "待付款"
        case .active: return "使用中"
        case .frozen: return "已凍結"
        case .expired: return "已過期"
        case .refunded: return "已退款"
        }
    }
}

// MARK: - Voucher Type Extensions

extension VoucherType {
    var displayName: String {
        switch self {
        case .session: return "次數券"
        case .storedValue: return "儲值券"
        case .package: return "套裝券"
        }
    }

    var color: Color {
        switch self {
        case .session: return .blue
        case .storedValue: return .green
        case .package: return .purple
        }
    }
}

// MARK: - Match Status Extensions

extension MatchStatus {
    var color: Color {
        switch self {
        case .open: return .green
        case .matched: return .blue
        case .closed: return .gray
        }
    }

    var displayName: String {
        switch self {
        case .open: return "徵求中"
        case .matched: return "已媒合"
        case .closed: return "已關閉"
        }
    }
}

// MARK: - Staff Role Extensions

extension StaffRole {
    var displayName: String {
        switch self {
        case .owner: return "負責人"
        case .manager: return "店長"
        case .seniorDesigner: return "資深設計師"
        case .designer: return "設計師"
        case .assistant: return "助理"
        }
    }
}

// MARK: - Staff Permissions

let staffPagePermissions: [StaffRole: Set<String>] = [
    .owner: ["dashboard", "schedule", "services", "staff", "orders",
             "customers", "portfolio", "analytics", "hours", "vouchers",
             "payroll", "performance", "marketing", "settings", "notifications"],
    .manager: ["dashboard", "schedule", "services", "staff", "orders",
               "customers", "portfolio", "analytics", "hours", "vouchers",
               "payroll", "performance", "marketing", "notifications"],
    .seniorDesigner: ["dashboard", "schedule", "orders", "customers", "portfolio"],
    .designer: ["dashboard", "schedule", "orders", "portfolio"],
    .assistant: ["dashboard", "schedule"]
]
