import Foundation
import UserNotifications
import AudioToolbox

/// Handles real-time booking alert notifications for merchants.
/// When a customer books, the merchant's app shows a push notification with sound.
@Observable
class BookingAlertService {
    static let shared = BookingAlertService()

    var isPermissionGranted = false

    private init() {}

    // MARK: - Permission

    /// Request notification permission. Call on first booking-related screen.
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            isPermissionGranted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            #if DEBUG
            print("[BookingAlert] Permission request failed: \(error)")
            #endif
        }
    }

    /// Check current permission status without prompting.
    func checkPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isPermissionGranted = settings.authorizationStatus == .authorized
    }

    // MARK: - Local Notification

    /// Show a local notification when a new booking comes in.
    /// Call this when the merchant's order list detects a new booking.
    func showNewBookingAlert(
        customerName: String,
        serviceName: String,
        date: String,
        time: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = "新預約來了！"
        content.body = "\(customerName) 預約了 \(serviceName)\n\(date) \(time)"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "new-booking-\(UUID().uuidString)",
            content: content,
            trigger: nil // deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                #if DEBUG
                print("[BookingAlert] Failed to schedule notification: \(error)")
                #endif
            }
        }

        // Also play a sound + haptic for foreground state
        playBookingSound()
    }

    /// Show a notification for booking status change (confirmed, cancelled, etc.)
    func showBookingStatusAlert(bookingId: String, status: BookingStatus, serviceName: String) {
        let content = UNMutableNotificationContent()

        switch status {
        case .confirmed:
            content.title = "預約已確認"
            content.body = "\(serviceName) 預約已確認"
        case .cancelled:
            content.title = "預約已取消"
            content.body = "\(serviceName) 預約已被取消"
        case .completed:
            content.title = "服務已完成"
            content.body = "\(serviceName) 服務已完成"
        default:
            return
        }

        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "booking-status-\(bookingId)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Sound & Haptics

    /// Play a "cha-ching" style feedback when a booking comes in or check-in succeeds.
    func playBookingSound() {
        // System sound + haptic
        AudioServicesPlaySystemSound(1394) // payment success sound
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
