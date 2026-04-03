import Foundation

/// Handles Universal Links and custom URL schemes for BeautyTime.
///
/// Supported deep link patterns:
///   https://www.btbeautytime.com/providers/{id}          → provider detail
///   https://www.btbeautytime.com/providers/{id}/book     → booking flow
///   beautytime://providers/{id}                          → provider detail
///   beautytime://providers/{id}/book                     → booking flow
enum DeepLinkRouter {

    enum Destination: Equatable {
        case providerDetail(providerId: String)
        case booking(providerId: String)
        case unknown
    }

    static func resolve(url: URL) -> Destination {
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        // Match: /providers/{id} or /providers/{id}/book
        if pathComponents.count >= 2, pathComponents[0] == "providers" {
            let providerId = pathComponents[1]
            if pathComponents.count >= 3, pathComponents[2] == "book" {
                return .booking(providerId: providerId)
            }
            return .providerDetail(providerId: providerId)
        }

        return .unknown
    }
}

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("deepLinkReceived")
    static let switchToMyBookings = Notification.Name("switchToMyBookings")
}
