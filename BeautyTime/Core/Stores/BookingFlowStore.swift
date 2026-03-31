import Foundation
import SwiftUI

enum BookingStep: Int, CaseIterable {
    case selectService = 1
    case selectDate = 2
    case selectStaffTime = 3
    case confirm = 4

    var title: String {
        switch self {
        case .selectService: return "選擇服務"
        case .selectDate: return "選擇日期"
        case .selectStaffTime: return "選擇設計師與時段"
        case .confirm: return "確認預約"
        }
    }
}

@Observable
class BookingFlowStore {
    var currentStep: BookingStep = .selectService
    var providerId: String = ""
    var provider: Provider?

    // Step 1: 選擇服務
    var services: [Service] = []
    var selectedService: Service?

    // Step 2: 選擇日期
    var availableDates: [AvailableDate] = []
    var selectedDate: String?

    // Step 3: 選設計師+時段
    var staffFindResult: StaffFindResponse?
    var selectedStaff: StaffMember?
    var selectedTime: String?

    // Step 4: 確認
    var note: String = ""
    var couponCode: String?
    var verifiedCoupon: Coupon?

    // Payment
    var paymentHTML: String?
    var merchantTradeNo: String?

    // State
    var isLoading = false
    var error: String?
    var createdBooking: Booking?

    private let api = APIClient.shared

    // MARK: - Computed

    var totalPrice: Double {
        selectedService?.price ?? 0
    }

    var depositAmount: Double {
        guard let rate = provider?.depositRate else { return totalPrice }
        return totalPrice * rate
    }

    var discountAmount: Double {
        guard let coupon = verifiedCoupon, let value = coupon.discountValue else { return 0 }
        switch coupon.discountType {
        case .percentage:
            return totalPrice * value / 100.0
        case .fixed:
            return value
        case .none:
            return 0
        }
    }

    var finalPrice: Double {
        max(0, totalPrice - discountAmount)
    }

    /// 取得目前選擇的設計師全部時段（含不可用）
    var currentAllSlots: [StaffTimeSlot] {
        guard let result = staffFindResult else { return [] }
        if let staff = selectedStaff,
           let slots = result.availableSlots[staff.id] {
            return slots.sorted { $0.time < $1.time }
        } else {
            // 不指定 → 合併所有員工時段，只要有一位可用就算可用
            var slotMap: [String: Bool] = [:]
            for slots in result.availableSlots.values {
                for slot in slots {
                    if slot.available {
                        slotMap[slot.time] = true
                    } else if slotMap[slot.time] == nil {
                        slotMap[slot.time] = false
                    }
                }
            }
            return slotMap.map { StaffTimeSlot(time: $0.key, available: $0.value) }
                .sorted { $0.time < $1.time }
        }
    }

    // MARK: - Step 1: 載入服務

    func loadServices() async {
        guard !providerId.isEmpty else { return }
        isLoading = true
        do {
            services = try await api.get(
                path: APIEndpoints.Services.list,
                queryItems: [URLQueryItem(name: "providerId", value: providerId)]
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Step 2: 載入可用日期

    func loadAvailableDates(month: String) async {
        guard selectedService != nil, !providerId.isEmpty else { return }
        isLoading = true
        do {
            let dates = generateDatesForMonth(month)
            let datesString = dates.joined(separator: ",")

            let queryItems = [
                URLQueryItem(name: "providerId", value: providerId),
                URLQueryItem(name: "dates", value: datesString)
            ]

            // 後端回傳 { "2026-03-30": true, "2026-03-31": false }
            let dateDict: [String: Bool] = try await api.get(
                path: APIEndpoints.Availability.dateBatch,
                queryItems: queryItems
            )
            availableDates = dateDict.map { AvailableDate(date: $0.key, available: $0.value) }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Step 3: 載入可用設計師+時段

    func loadAvailableStaffForDate() async {
        guard let date = selectedDate, !providerId.isEmpty else { return }
        isLoading = true
        do {
            // GET /api/availability/staff/find?providerId=&date=&serviceId=
            var queryItems = [
                URLQueryItem(name: "providerId", value: providerId),
                URLQueryItem(name: "date", value: date)
            ]
            if let serviceId = selectedService?.id {
                queryItems.append(URLQueryItem(name: "serviceId", value: serviceId))
            }
            staffFindResult = try await api.get(
                path: APIEndpoints.Availability.staffFind,
                queryItems: queryItems
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Step 4: 驗證優惠碼

    func verifyCoupon() async {
        guard let code = couponCode, !code.isEmpty else { return }
        isLoading = true
        do {
            let response: CouponVerifyResponse = try await api.post(
                path: APIEndpoints.Coupons.verify,
                body: ["code": code, "providerId": providerId]
            )
            if response.valid {
                verifiedCoupon = response.coupon
            } else {
                error = response.message ?? "優惠碼無效"
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - 建立預約

    func createBooking() async {
        guard let service = selectedService,
              let date = selectedDate,
              let time = selectedTime else { return }
        isLoading = true
        do {
            var dict: [String: Any] = [
                "providerId": providerId,
                "serviceId": service.id,
                "date": date,
                "time": time,
                "totalPrice": finalPrice
            ]
            if let staff = selectedStaff { dict["staffId"] = staff.id }
            if !note.isEmpty { dict["note"] = note }
            if let coupon = verifiedCoupon { dict["couponId"] = coupon.id }

            let booking: Booking = try await api.post(
                path: APIEndpoints.Bookings.create,
                body: JSONBody(dict)
            )
            createdBooking = booking
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - 付款

    func createPayment() async {
        guard let booking = createdBooking else { return }
        isLoading = true
        do {
            let response: BookingPayResponse = try await api.post(
                path: APIEndpoints.Bookings.pay(booking.id)
            )
            merchantTradeNo = response.payment?.merchantTradeNo
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func checkPaymentResult() async -> PaymentResult? {
        guard let tradeNo = merchantTradeNo else { return nil }
        do {
            return try await api.get(
                path: APIEndpoints.Payments.result,
                queryItems: [URLQueryItem(name: "merchantTradeNo", value: tradeNo)]
            )
        } catch {
            return nil
        }
    }

    // MARK: - Navigation

    func nextStep() {
        guard let next = BookingStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func previousStep() {
        guard let prev = BookingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    func reset() {
        currentStep = .selectService
        selectedService = nil
        selectedStaff = nil
        selectedDate = nil
        selectedTime = nil
        staffFindResult = nil
        note = ""
        couponCode = nil
        verifiedCoupon = nil
        paymentHTML = nil
        merchantTradeNo = nil
        createdBooking = nil
        error = nil
    }

    // MARK: - Helpers

    private func generateDatesForMonth(_ month: String) -> [String] {
        let parseFormatter = DateFormatter()
        parseFormatter.dateFormat = "yyyy-MM"
        parseFormatter.locale = Locale(identifier: "en_US_POSIX")
        guard let startDate = parseFormatter.date(from: month) else { return [] }

        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: startDate) else { return [] }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd"
        outputFormatter.locale = Locale(identifier: "en_US_POSIX")

        return range.compactMap { day -> String? in
            guard let date = calendar.date(bySetting: .day, value: day, of: startDate) else { return nil }
            if date < calendar.startOfDay(for: Date()) { return nil }
            return outputFormatter.string(from: date)
        }
    }
}
