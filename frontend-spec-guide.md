# BeautyTime iOS 開發指南

## 目錄

1. [專案概述](#專案概述)
2. [系統架構](#系統架構)
3. [環境設定](#環境設定)
4. [認證機制](#認證機制)
5. [API 端點參考](#api-端點參考)
6. [資料模型](#資料模型)
7. [頁面與功能對照](#頁面與功能對照)
8. [預約流程](#預約流程)
9. [付款整合 (ECPay)](#付款整合-ecpay)
10. [票券系統](#票券系統)
11. [媒合系統](#媒合系統)
12. [多語系支援](#多語系支援)
13. [常數與列舉](#常數與列舉)
14. [建議的 iOS 架構](#建議的-ios-架構)

---

## 專案概述

BeautyTime 是一個美業預約平台，包含三種角色：

- **顧客 (Customer)** — 搜尋服務商、預約服務、購買票券
- **服務商 (Provider)** — 管理服務、員工、訂單、行銷
- **平台管理員 (Platform Admin)** — 管理商家、訂單、公告、爭議處理

### 技術架構概覽

```
iOS App ──→ NestJS API Backend ──→ Supabase PostgreSQL
                 ↑
Web Frontend (Next.js) ─┘
```

iOS App 與現有 Web 前端共用同一個 NestJS API 後端，不直接連接資料庫。

---

## 系統架構

### API 基礎資訊

| 項目 | 值 |
|------|-----|
| Base URL (Production) | `https://api.btbeautytime.com` |
| 認證方式 | Bearer Token (JWT) |
| Token Cookie 名稱 | `bt_token` |
| Token 有效期 | 30 天 |
| Content-Type | `application/json` |

### 請求標頭

```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

---

## 環境設定

### 需要的 Configuration

```swift
enum AppConfig {
    static let apiBaseURL = "https://api.btbeautytime.com"
    static let supabaseURL = "https://<project>.supabase.co"  // 若需要 Realtime
    static let siteURL = "https://www.btbeautytime.com"

    // ECPay (用於支付 WebView)
    static let ecpayMerchantID = "3002607"
}
```

### 建議的 iOS 最低版本

- iOS 16.0+（支援 SwiftUI NavigationStack、新版 Charts）

### 建議的第三方套件

| 套件 | 用途 |
|------|------|
| Alamofire / URLSession | HTTP 網路層 |
| KeychainAccess | JWT Token 安全儲存 |
| Kingfisher | 圖片載入與快取 |
| Supabase Swift SDK | Realtime 訂閱（選用） |

---

## 認證機制

### 登入流程（Email OTP）

```
1. POST /api/auth/send-otp   { email }         → 發送驗證碼
2. POST /api/auth/verify-otp  { email, otp }    → 回傳 JWT Token
3. 儲存 Token 至 Keychain
4. GET /api/auth/me                             → 取得用戶資料
```

### OAuth 登入

支援三種 OAuth Provider：

#### LINE Login
```
POST /api/auth/line
Body: { code: "<authorization_code>", redirectUri: "<redirect_uri>" }
Response: { token, user }
```

#### Apple Sign In
```
POST /api/auth/apple
Body: { identityToken: "<identity_token>", authorizationCode: "<auth_code>", fullName?: "<name>" }
Response: { token, user }
```

#### Google Sign In
```
POST /api/auth/google
Body: { idToken: "<google_id_token>" }
Response: { token, user }
```

### Token 管理

- JWT 存放於 Keychain，有效期 30 天
- 每次 API 請求附帶 `Authorization: Bearer <token>`
- Token 過期時引導用戶重新登入
- 檢查 Email 是否已註冊：`GET /api/auth/check-email?email=<email>`

---

## API 端點參考

### 認證 (Auth)

| Method | Endpoint | 說明 |
|--------|----------|------|
| POST | `/api/auth/send-otp` | 發送 OTP 至 Email |
| POST | `/api/auth/verify-otp` | 驗證 OTP，回傳 JWT |
| GET | `/api/auth/check-email?email=` | 檢查 Email 是否存在 |
| POST | `/api/auth/google` | Google OAuth |
| POST | `/api/auth/line` | LINE OAuth |
| POST | `/api/auth/apple` | Apple OAuth |
| GET | `/api/auth/me` | 取得當前用戶資料 |

### 服務商 (Providers)

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/api/providers` | 搜尋/篩選服務商 |
| GET | `/api/providers/{id}` | 服務商詳細資料 |
| POST | `/api/providers/register` | 註冊成為服務商 |
| PATCH | `/api/providers/{id}` | 更新服務商資料 |

**搜尋參數：**
```
GET /api/providers?category=nail&city=taipei&district=daan&q=keyword&page=1&limit=20
```

### 服務 (Services)

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/api/services?providerId={id}` | 取得服務商的服務列表 |
| POST | `/api/services` | 建立服務 |
| PATCH | `/api/services/{id}` | 更新服務 |
| DELETE | `/api/services/{id}` | 刪除服務 |

### 員工 (Staff)

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/api/staff?providerId={id}` | 取得員工列表 |
| POST | `/api/staff` | 建立員工 |
| PATCH | `/api/staff/{id}` | 更新員工 |
| DELETE | `/api/staff/{id}` | 刪除員工 |

### 預約 (Bookings)

| Method | Endpoint | 說明 |
|--------|----------|------|
| POST | `/api/bookings` | 建立預約 |
| GET | `/api/bookings/my` | 取得顧客的預約列表 |
| GET | `/api/bookings/provider?providerId={id}` | 取得服務商的預約 |
| PATCH | `/api/bookings/{id}/cancel` | 取消預約 |
| PATCH | `/api/bookings/{id}/confirm` | 確認預約 |
| PATCH | `/api/bookings/{id}/complete` | 完成預約 |
| PATCH | `/api/bookings/{id}/dispute` | 提出爭議 |

### 時段查詢 (Availability)

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/api/availability/staff?providerId={id}&serviceId={id}&date={date}` | 可用員工 |
| GET | `/api/availability/date?providerId={id}&serviceId={id}&staffId={id}&month={month}` | 可用日期 |

### 付款 (Payments)

| Method | Endpoint | 說明 |
|--------|----------|------|
| POST | `/api/payments` | 建立付款 |
| GET | `/api/payments/result?merchantTradeNo={no}` | 查詢付款結果 |
| POST | `/api/payments/callback` | ECPay 回調 (Server-to-Server) |

### 票券 (Vouchers)

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/api/vouchers/plans?providerId={id}` | 取得票券方案 |
| POST | `/api/vouchers/plans` | 建立票券方案 |
| PATCH | `/api/vouchers/plans/{id}` | 更新票券方案 |
| DELETE | `/api/vouchers/plans/{id}` | 刪除票券方案 |
| POST | `/api/vouchers/purchase/{planId}` | 購買票券 |
| GET | `/api/vouchers/my` | 取得我的票券 |
| GET | `/api/vouchers/provider?providerId={id}` | 取得服務商的票券 |
| POST | `/api/vouchers/{id}/generate-token` | 產生兌換 Token |
| POST | `/api/vouchers/verify-token` | 驗證兌換 Token |
| POST | `/api/vouchers/redeem` | 兌換票券 |
| POST | `/api/vouchers/{id}/cancel` | 取消票券 |
| GET | `/api/vouchers/{id}/transactions` | 票券交易紀錄 |
| GET | `/api/vouchers/transactions/batch-count` | 批次取得交易數量 |

### 評論 (Reviews)

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/api/reviews?providerId={id}` | 取得服務商的評論 |
| POST | `/api/reviews` | 建立評論 |

### 收藏 (Favorites)

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/api/favorites` | 取得收藏列表 |
| POST | `/api/favorites` | 新增收藏 |
| DELETE | `/api/favorites/{providerId}` | 移除收藏 |

### 媒合 (Match)

| Method | Endpoint | 說明 |
|--------|----------|------|
| POST | `/api/match/requests` | 建立媒合需求 |
| GET | `/api/match/requests/my` | 取得我的媒合需求 |
| GET | `/api/match/requests/{id}` | 媒合需求詳情 |
| PATCH | `/api/match/requests/{id}/close` | 關閉媒合需求 |
| GET | `/api/match/requests/available` | 取得可報價的需求 |
| POST | `/api/match/offers` | 送出報價 |
| PATCH | `/api/match/offers/{id}/accept` | 接受報價 |
| PATCH | `/api/match/offers/{id}/reject` | 拒絕報價 |

### 作品集 (Portfolio)

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/api/portfolio?providerId={id}` | 取得作品集 |
| POST | `/api/portfolio` | 新增作品 |
| DELETE | `/api/portfolio/{id}` | 刪除作品 |

### 分析 (Analytics) — 服務商用

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/api/analytics/revenue?providerId={id}&period=month` | 營收數據 |
| GET | `/api/analytics/service-revenue?providerId={id}` | 各服務營收 |
| GET | `/api/analytics/return-rate?providerId={id}` | 回客率 |
| GET | `/api/analytics/customer-mix?providerId={id}` | 新客/回客比例 |

### 營業時間 (Business Hours)

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/api/hours?providerId={id}` | 取得營業時間 |
| PUT | `/api/hours?providerId={id}` | 更新營業時間 |

### 通知 (Notifications)

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/api/notifications` | 取得通知列表 |
| PATCH | `/api/notifications/{id}/read` | 標記已讀 |

### 顧客 (Customers) — 服務商用

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/api/customers?providerId={id}` | 顧客列表 |
| POST | `/api/customers/notes` | 新增顧客備註 |

### 優惠券 (Coupons)

| Method | Endpoint | 說明 |
|--------|----------|------|
| POST | `/api/coupons/verify` | 驗證優惠碼 |

### 薪資 (Payroll) — 服務商用

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/api/commission/settings?providerId={id}` | 取得佣金設定 |
| PUT | `/api/commission/settings` | 更新佣金設定 |
| GET | `/api/payroll?providerId={id}&month={m}&year={y}` | 取得薪資紀錄 |
| POST | `/api/payroll/calculate` | 計算薪資 |

### 公告 (Announcements)

| Method | Endpoint | 說明 |
|--------|----------|------|
| GET | `/api/announcements/active` | 取得有效公告 |

---

## 資料模型

### Swift Model 定義

```swift
// MARK: - User & Profile

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String?
    let avatarUrl: String?
    let phone: String?
    let phoneVerified: Bool
    let role: UserRole
    let preferredLocale: AppLocale
    let surveyCompleted: Bool
    let createdAt: Date
}

enum UserRole: String, Codable {
    case customer, provider, both
}

enum AppLocale: String, Codable {
    case zhTW = "zh-TW"
    case en
}

// MARK: - Provider

struct Provider: Codable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let category: ServiceCategory
    let description: String?
    let address: String?
    let city: String?
    let district: String?
    let phone: String?
    let imageUrl: String?
    let rating: Double?
    let reviewCount: Int
    let isVerified: Bool
    let isActive: Bool
    let depositRate: Double?
    let instagramUrl: String?
    let reviewNote: String?
    let createdAt: Date
}

// MARK: - Staff

struct StaffMember: Codable, Identifiable {
    let id: String
    let providerId: String
    let userId: String?
    let role: StaffRole
    let name: String
    let title: String?
    let photoUrl: String?
    let specialties: [String]?
    let rating: Double?
    let reviewCount: Int
    let isActive: Bool
}

enum StaffRole: String, Codable {
    case owner, manager, seniorDesigner = "senior_designer"
    case designer, assistant
}

// MARK: - Service

struct Service: Codable, Identifiable {
    let id: String
    let providerId: String
    let name: String
    let description: String?
    let category: String?
    let duration: Int          // 分鐘
    let price: Double
    let isAvailable: Bool
    let sortOrder: Int?
}

// MARK: - Booking

struct Booking: Codable, Identifiable {
    let id: String
    let customerId: String
    let providerId: String
    let serviceId: String
    let staffId: String?
    let date: String           // "YYYY-MM-DD"
    let time: String           // "HH:mm"
    let duration: Int
    let totalPrice: Double
    let depositAmount: Double?
    let depositPaid: Bool
    let status: BookingStatus
    let cancellationReason: String?
    let note: String?
    let createdAt: Date

    // Nested relations (expanded by API)
    let service: Service?
    let provider: Provider?
    let staff: StaffMember?
    let customer: User?
}

enum BookingStatus: String, Codable {
    case pending, confirmed, completed, cancelled, disputed
}

// MARK: - Review

struct Review: Codable, Identifiable {
    let id: String
    let bookingId: String
    let customerId: String
    let providerId: String
    let staffId: String?
    let rating: Int            // 1-5
    let comment: String?
    let imageUrls: [String]?
    let createdAt: Date
    let customer: User?
}

// MARK: - Payment

struct Payment: Codable, Identifiable {
    let id: String
    let bookingId: String
    let customerId: String
    let amount: Double
    let depositAmount: Double?
    let paymentMethod: String?
    let status: PaymentStatus
    let transactionId: String?
    let ecpayTradeNo: String?
    let paidAt: Date?
}

enum PaymentStatus: String, Codable {
    case pending, paid, refunded, failed
}

// MARK: - Voucher

struct VoucherPlan: Codable, Identifiable {
    let id: String
    let providerId: String
    let type: VoucherType
    let name: String
    let description: String?
    let originalPrice: Double
    let sellingPrice: Double
    let sessionsTotal: Int?
    let bonusAmount: Double?
    let validDays: Int
    let applicableServices: [String]?
    let maxSales: Int?
    let soldCount: Int
    let isActive: Bool
}

enum VoucherType: String, Codable {
    case session, storedValue = "stored_value", package
}

struct CustomerVoucher: Codable, Identifiable {
    let id: String
    let planId: String
    let customerId: String
    let providerId: String
    let purchasePrice: Double
    let sessionsRemaining: Int?
    let balanceRemaining: Double?
    let packageRemaining: [String: Int]?
    let status: VoucherStatus
    let purchasedAt: Date
    let expiresAt: Date?
    let lastUsedAt: Date?
}

enum VoucherStatus: String, Codable {
    case active, frozen, expired, refunded
}

struct VoucherTransaction: Codable, Identifiable {
    let id: String
    let voucherId: String
    let bookingId: String?
    let type: VoucherTransactionType
    let sessionsUsed: Int?
    let amountUsed: Double?
    let upgradeFee: Double?
    let serviceId: String?
    let staffId: String?
    let note: String?
    let createdAt: Date
}

enum VoucherTransactionType: String, Codable {
    case redeem, upgrade, refund, extend, freeze, unfreeze
}

// MARK: - Match

struct MatchRequest: Codable, Identifiable {
    let id: String
    let customerId: String
    let serviceType: String
    let preferredDate: String?
    let preferredTime: String?
    let locationCity: String?
    let locationDistrict: String?
    let budgetMin: Double?
    let budgetMax: Double?
    let photoUrl: String?
    let note: String?
    let status: MatchStatus
    let createdAt: Date
    let expiresAt: Date?
}

enum MatchStatus: String, Codable {
    case open, matched, closed
}

struct MatchOffer: Codable, Identifiable {
    let id: String
    let requestId: String
    let providerId: String
    let quotedPrice: Double
    let availableSlots: [String]?
    let portfolioUrls: [String]?
    let message: String?
    let status: MatchOfferStatus
    let createdAt: Date
    let provider: Provider?
}

enum MatchOfferStatus: String, Codable {
    case pending, accepted, rejected
}

// MARK: - Portfolio

struct PortfolioItem: Codable, Identifiable {
    let id: String
    let providerId: String
    let beforePhotoUrl: String?
    let afterPhotoUrl: String?
    let description: String?
    let styleTags: [String]?
    let createdAt: Date
}

// MARK: - Business Hours

struct BusinessHour: Codable, Identifiable {
    let id: String
    let providerId: String
    let dayOfWeek: Int         // 0=Sunday, 6=Saturday
    let openTime: String       // "09:00"
    let closeTime: String      // "18:00"
    let isOpen: Bool
}

// MARK: - Analytics

struct RevenueData: Codable {
    let totalRevenue: Double
    let bookingCount: Int
    let averageOrderValue: Double
    let periodData: [PeriodRevenue]
}

struct PeriodRevenue: Codable {
    let period: String
    let revenue: Double
    let count: Int
}

// MARK: - Commission & Payroll

struct CommissionSettings: Codable {
    let id: String
    let providerId: String
    let salaryModel: String
    let defaultCommissionRate: Double
    let commissionType: CommissionType
    let productCommissionRate: Double?
}

enum CommissionType: String, Codable {
    case flat, tiered
}

struct PayrollRecord: Codable, Identifiable {
    let id: String
    let providerId: String
    let staffId: String
    let month: Int
    let year: Int
    let baseSalary: Double
    let commission: Double
    let deductions: Double
    let totalAmount: Double
    let status: PayrollStatus
}

enum PayrollStatus: String, Codable {
    case draft, confirmed, paid
}

// MARK: - Coupon

struct Coupon: Codable, Identifiable {
    let id: String
    let code: String
    let description: String?
    let discountType: DiscountType
    let discountValue: Double
    let minOrderAmount: Double?
    let validFrom: Date?
    let validUntil: Date?
    let isActive: Bool
}

enum DiscountType: String, Codable {
    case percentage, fixed
}

// MARK: - Notification

struct AppNotification: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String
    let body: String
    let type: String?
    let isRead: Bool
    let createdAt: Date
}
```

---

## 頁面與功能對照

### 顧客端頁面

| Web 路徑 | iOS 對應畫面 | 功能說明 |
|----------|-------------|----------|
| `/` | `ExploreView` | 首頁，搜尋/篩選服務商（分類、城市、風格） |
| `/providers/{id}` | `ProviderDetailView` | 服務商詳情（評論、服務、員工、作品集） |
| `/providers/{id}/book` | `BookingFlowView` | 預約流程（5 步驟精靈） |
| `/bookings` | `MyBookingsView` | 我的預約列表 |
| `/match` | `MatchListView` | 媒合需求列表 |
| `/match/new` | `CreateMatchView` | 建立媒合需求 |
| `/match/{id}` | `MatchDetailView` | 媒合需求詳情與報價 |
| `/profile` | `ProfileView` | 個人檔案首頁 |
| `/profile/edit` | `EditProfileView` | 編輯個人資料 |
| `/profile/favorites` | `FavoritesView` | 收藏的服務商 |
| `/profile/vouchers` | `MyVouchersView` | 我的票券 |
| `/profile/coupons` | `MyCouponsView` | 我的優惠券 |
| `/profile/notifications` | `NotificationsView` | 通知設定 |
| `/profile/unpaid` | `UnpaidOrdersView` | 未付款訂單 |
| `/auth/sign-in` | `SignInView` | 登入（Email OTP） |
| `/auth/sign-up` | `SignUpView` | 註冊 |

### 服務商端頁面

| Web 路徑 | iOS 對應畫面 | 功能說明 |
|----------|-------------|----------|
| `/manage` | `DashboardView` | 管理後台首頁 |
| `/manage/schedule` | `ScheduleView` | 排班管理 |
| `/manage/services` | `ServicesManageView` | 服務管理 CRUD |
| `/manage/staff` | `StaffManageView` | 員工管理 |
| `/manage/orders` | `OrdersManageView` | 訂單管理 |
| `/manage/customers` | `CustomersView` | 顧客列表與備註 |
| `/manage/portfolio` | `PortfolioManageView` | 作品集管理 |
| `/manage/analytics` | `AnalyticsView` | 營收與績效報表 |
| `/manage/hours` | `BusinessHoursView` | 營業時間設定 |
| `/manage/vouchers` | `VoucherPlansView` | 票券方案管理 |
| `/manage/payroll` | `PayrollView` | 薪資計算 |
| `/manage/settings` | `ProviderSettingsView` | 服務商設定 |

---

## 預約流程

預約是一個 5 步驟精靈流程：

```
Step 1: 選擇服務 (SelectService)
    ↓
Step 2: 選擇設計師 (SelectStaff)
    ↓
Step 3: 選擇日期時間 (SelectDateTime)
    ↓
Step 4: 確認資訊 (Confirm)
    ↓
Step 5: 付款 (Payment)
```

### iOS 狀態管理建議

```swift
@Observable
class BookingFlowStore {
    var currentStep: BookingStep = .selectService
    var selectedService: Service?
    var selectedStaff: StaffMember?
    var selectedDate: String?      // "YYYY-MM-DD"
    var selectedTime: String?      // "HH:mm"
    var note: String = ""
    var couponCode: String?

    // 計算屬性
    var totalPrice: Double { ... }
    var depositAmount: Double { ... }
}

enum BookingStep: Int, CaseIterable {
    case selectService = 1
    case selectStaff = 2
    case selectDateTime = 3
    case confirm = 4
    case payment = 5
}
```

### API 呼叫順序

1. `GET /api/services?providerId={id}` — 取得服務列表
2. `GET /api/availability/staff?providerId={id}&serviceId={id}&date={date}` — 可用設計師
3. `GET /api/availability/date?providerId={id}&serviceId={id}&staffId={id}&month={month}` — 可用日期
4. `POST /api/coupons/verify` — 驗證優惠碼（選用）
5. `POST /api/bookings` — 建立預約
6. `POST /api/payments` — 建立付款（取得 ECPay 付款頁面）

---

## 付款整合 (ECPay)

### 流程

```
iOS App → POST /api/payments → 取得 ECPay HTML Form
       → WKWebView 載入 ECPay 付款頁面
       → 用戶完成付款
       → ECPay Server → POST /api/payments/callback (Server-to-Server)
       → iOS App Polling: GET /api/payments/result?merchantTradeNo={no}
       → 顯示付款結果
```

### iOS 實作要點

```swift
// 1. 建立付款，取得 ECPay Form HTML
let paymentResponse = try await api.createPayment(bookingId: booking.id)

// 2. 在 WKWebView 中載入 HTML
let webView = WKWebView()
webView.loadHTMLString(paymentResponse.html, baseURL: nil)

// 3. 監聽付款完成（Polling 或攔截 returnURL）
// returnURL 會導向: {siteURL}/payments/result?merchantTradeNo=xxx
// 在 WKWebView navigationDelegate 中攔截此 URL

// 4. 查詢付款結果
let result = try await api.getPaymentResult(merchantTradeNo: tradeNo)
```

### 支援的付款方式

| 付款方式 | 代碼 |
|---------|------|
| 信用卡 | `Credit` |
| ATM 轉帳 | `ATM` |
| 超商代碼 | `CVS` |
| Apple Pay | `ApplePay` |
| LINE Pay | `LinePay` |

---

## 票券系統

### 票券類型

| 類型 | 說明 |
|------|------|
| `session` | 次數券（如：10次美甲） |
| `stored_value` | 儲值券（如：儲值 5000 送 500） |
| `package` | 套裝券（如：美甲+美睫組合） |

### 票券生命週期

```
購買 → active → (使用中) → expired
                ↓
              frozen → unfreeze → active
                ↓
              refunded
```

### 兌換流程（QR Code）

```
顧客端:
1. POST /api/vouchers/{id}/generate-token → 產生一次性 Token
2. 產生 QR Code 包含此 Token

服務商端:
3. 掃描 QR Code 取得 Token
4. POST /api/vouchers/verify-token { token } → 取得票券資訊
5. POST /api/vouchers/redeem { token, serviceId, staffId } → 完成兌換
```

---

## 媒合系統

### 流程

```
顧客發布需求 (MatchRequest)
    ↓
服務商瀏覽可用需求
    ↓
服務商送出報價 (MatchOffer)
    ↓
顧客查看報價 → 接受/拒絕
    ↓
接受後 → 轉為預約流程
```

---

## 多語系支援

應用程式支援兩種語言：

| 語言 | 代碼 |
|------|------|
| 繁體中文 | `zh-TW` |
| English | `en` |

### iOS 實作建議

使用 `String(localized:)` 或 `.strings` / `.xcstrings` 檔案管理翻譯。用戶偏好語言儲存在 Profile 的 `preferredLocale` 欄位。

---

## 常數與列舉

### 服務分類

```swift
enum ServiceCategory: String, Codable, CaseIterable {
    case nail = "nail"           // 美甲
    case eyelash = "eyelash"     // 美睫
    case hair = "hair"           // 美髮
    case skin = "skin"           // 美膚
    case massage = "massage"     // 按摩
    case makeup = "makeup"       // 彩妝
    case waxing = "waxing"       // 除毛
    case tattoo = "tattoo"       // 紋繡
    case other = "other"         // 其他

    var displayName: String {
        switch self {
        case .nail: return "美甲"
        case .eyelash: return "美睫"
        case .hair: return "美髮"
        case .skin: return "美膚"
        case .massage: return "按摩"
        case .makeup: return "彩妝"
        case .waxing: return "除毛"
        case .tattoo: return "紋繡"
        case .other: return "其他"
        }
    }
}
```

### 台灣城市

```swift
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
```

### 預約狀態顏色

```swift
extension BookingStatus {
    var color: Color {
        switch self {
        case .pending:   return .orange
        case .confirmed: return .blue
        case .completed: return .green
        case .cancelled: return .gray
        case .disputed:  return .red
        }
    }

    var displayName: String {
        switch self {
        case .pending:   return "待確認"
        case .confirmed: return "已確認"
        case .completed: return "已完成"
        case .cancelled: return "已取消"
        case .disputed:  return "爭議中"
        }
    }
}
```

### 員工權限

```swift
// 各角色可存取的管理頁面
let staffPagePermissions: [StaffRole: Set<String>] = [
    .owner:          ["dashboard", "schedule", "services", "staff", "orders",
                      "customers", "portfolio", "analytics", "hours", "vouchers",
                      "payroll", "performance", "marketing", "settings", "notifications"],
    .manager:        ["dashboard", "schedule", "services", "staff", "orders",
                      "customers", "portfolio", "analytics", "hours", "vouchers",
                      "payroll", "performance", "marketing", "notifications"],
    .seniorDesigner: ["dashboard", "schedule", "orders", "customers", "portfolio"],
    .designer:       ["dashboard", "schedule", "orders", "portfolio"],
    .assistant:      ["dashboard", "schedule"]
]
```

---

## 建議的 iOS 架構

### 專案結構

```
BeautyTime/
├── App/
│   ├── BeautyTimeApp.swift
│   ├── AppDelegate.swift
│   └── ContentView.swift
├── Core/
│   ├── Network/
│   │   ├── APIClient.swift           # HTTP 客戶端
│   │   ├── APIEndpoints.swift        # 端點定義
│   │   ├── APIError.swift            # 錯誤處理
│   │   └── TokenManager.swift        # JWT 管理
│   ├── Models/                       # 資料模型（參考上方定義）
│   ├── Stores/                       # @Observable 狀態管理
│   │   ├── AuthStore.swift
│   │   ├── BookingFlowStore.swift
│   │   └── UserStore.swift
│   ├── Extensions/
│   └── Utilities/
│       ├── Constants.swift           # 常數與列舉
│       └── Formatters.swift          # 日期、價格格式化
├── Features/
│   ├── Auth/
│   │   ├── SignInView.swift
│   │   ├── SignUpView.swift
│   │   └── OTPInputView.swift
│   ├── Explore/
│   │   ├── ExploreView.swift
│   │   ├── ProviderCard.swift
│   │   └── FilterSheet.swift
│   ├── Provider/
│   │   ├── ProviderDetailView.swift
│   │   ├── ReviewsSection.swift
│   │   └── PortfolioSection.swift
│   ├── Booking/
│   │   ├── BookingFlowView.swift
│   │   ├── SelectServiceStep.swift
│   │   ├── SelectStaffStep.swift
│   │   ├── SelectDateTimeStep.swift
│   │   ├── ConfirmStep.swift
│   │   └── PaymentStep.swift
│   ├── MyBookings/
│   │   ├── MyBookingsView.swift
│   │   └── BookingDetailView.swift
│   ├── Match/
│   │   ├── MatchListView.swift
│   │   ├── CreateMatchView.swift
│   │   └── MatchDetailView.swift
│   ├── Voucher/
│   │   ├── MyVouchersView.swift
│   │   └── VoucherDetailView.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   ├── EditProfileView.swift
│   │   └── FavoritesView.swift
│   ├── Manage/                       # 服務商管理
│   │   ├── DashboardView.swift
│   │   ├── ServicesManageView.swift
│   │   ├── StaffManageView.swift
│   │   ├── OrdersManageView.swift
│   │   ├── AnalyticsView.swift
│   │   └── ...
│   └── Payment/
│       └── ECPayWebView.swift        # WKWebView 付款頁
├── Components/                       # 共用 UI 元件
│   ├── LoadingView.swift
│   ├── EmptyStateView.swift
│   ├── SearchBar.swift
│   ├── RatingStars.swift
│   └── QRCodeView.swift
└── Resources/
    ├── Localizable.xcstrings         # 多語系
    ├── Assets.xcassets
    └── Info.plist
```

### API Client 範例

```swift
actor APIClient {
    static let shared = APIClient()

    private let baseURL = AppConfig.apiBaseURL
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func request<T: Decodable>(
        _ method: HTTPMethod,
        path: String,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        var components = URLComponents(string: "\(baseURL)\(path)")!
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 附加 JWT Token
        if let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        return try decoder.decode(T.self, from: data)
    }
}
```

### 注意事項

1. **JSON Key 格式**：API 使用 `snake_case`，Swift 模型使用 `camelCase`，設定 `keyDecodingStrategy = .convertFromSnakeCase`
2. **日期格式**：部分日期欄位是 ISO 8601 字串，部分是 `"YYYY-MM-DD"` 純字串，需要分別處理
3. **圖片 CDN**：圖片存放於 Supabase Storage，URL 格式為 `https://<project>.supabase.co/storage/v1/object/public/<bucket>/<path>`
4. **即時更新**：可考慮使用 Supabase Realtime 訂閱預約狀態變更
5. **推播通知**：需整合 APNs，後端已有通知系統
6. **深層連結**：處理付款回調的 Universal Links

---

## 快速開始檢查清單

- [ ] 建立 Xcode 專案 (iOS 16+, SwiftUI)
- [ ] 設定 API Base URL
- [ ] 實作 Token 管理 (Keychain)
- [ ] 實作 APIClient
- [ ] 實作登入流程 (Email OTP + Apple Sign In)
- [ ] 實作首頁探索頁面
- [ ] 實作服務商詳情頁
- [ ] 實作預約流程
- [ ] 實作 ECPay WebView 付款
- [ ] 實作我的預約列表
- [ ] 實作個人檔案頁面
- [ ] 實作票券系統
- [ ] 實作媒合系統
- [ ] 實作服務商管理後台
- [ ] 整合推播通知
- [ ] 多語系處理
- [ ] 測試與上架
