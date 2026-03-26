import Foundation
import SwiftUI

enum BookingStep: Int, CaseIterable {
    case selectService = 1
    case selectDateTime = 2
    case selectStaff = 3
    case confirm = 4
    case payment = 5

    var title: String {
        switch self {
        case .selectService: return "選擇服務"
        case .selectDateTime: return "選擇日期"
        case .selectStaff: return "選擇時段與設計師"
        case .confirm: return "確認資訊"
        case .payment: return "付款"
        }
    }
}

@Observable
class BookingFlowStore {
    var currentStep: BookingStep = .selectService
    var providerId: String = ""
    var provider: Provider?

    // Step 1
    var services: [Service] = []
    var selectedService: Service?

    // Step 2
    var availableStaff: [AvailableStaff] = []
    var selectedStaff: StaffMember?

    // Step 3
    var availableDates: [AvailableDate] = []
    var selectedDate: String?
    var selectedTime: String?
    var availableSlots: [String] = []

    // Step 4
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

    // MARK: - Actions

    func loadServices() async {
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

    func loadAvailableStaff(date: String) async {
        guard let service = selectedService else { return }
        isLoading = true
        do {
            availableStaff = try await api.get(
                path: APIEndpoints.Availability.staff,
                queryItems: [
                    URLQueryItem(name: "providerId", value: providerId),
                    URLQueryItem(name: "serviceId", value: service.id),
                    URLQueryItem(name: "date", value: date)
                ]
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadAvailableDates(month: String) async {
        guard let service = selectedService else { return }
        isLoading = true
        do {
            // Generate all dates for the month
            let dates = generateDatesForMonth(month)
            let datesString = dates.joined(separator: ",")

            var queryItems = [
                URLQueryItem(name: "providerId", value: providerId),
                URLQueryItem(name: "dates", value: datesString)
            ]
            if let staffId = selectedStaff?.id {
                queryItems.append(URLQueryItem(name: "staffId", value: staffId))
            }

            availableDates = try await api.get(
                path: APIEndpoints.Availability.dateBatch,
                queryItems: queryItems
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func generateDatesForMonth(_ month: String) -> [String] {
        guard let startDate = Formatters.monthFormatter.date(from: month) else { return [] }

        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: startDate) else { return [] }

        return range.compactMap { day -> String? in
            guard let date = calendar.date(bySetting: .day, value: day, of: startDate) else { return nil }
            // Skip past dates
            if date < calendar.startOfDay(for: Date()) { return nil }
            return Formatters.dateFormatter.string(from: date)
        }
    }

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

    func createPayment() async {
        guard let booking = createdBooking else { return }
        isLoading = true
        do {
            // POST /api/bookings/{id}/pay returns { payment: { merchantTradeNo, ... } }
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
            let result: PaymentResult = try await api.get(
                path: APIEndpoints.Payments.result,
                queryItems: [URLQueryItem(name: "merchantTradeNo", value: tradeNo)]
            )
            return result
        } catch {
            return nil
        }
    }

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
        note = ""
        couponCode = nil
        verifiedCoupon = nil
        paymentHTML = nil
        merchantTradeNo = nil
        createdBooking = nil
        error = nil
    }
}
