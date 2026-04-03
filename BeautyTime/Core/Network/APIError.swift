import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case unauthorized
    case networkError(Error)
    case rateLimited(retryAfter: Int?)
    case conflict
    case tokenExpired

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無效的網址"
        case .invalidResponse: return "無效的回應"
        case .httpError(let statusCode, let data):
            if statusCode >= 500 {
                return "伺服器暫時無法處理請求，請稍後再試"
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let message = json["message"] as? String {
                    return message
                }
                if let messages = json["message"] as? [String], let first = messages.first {
                    return first
                }
            }
            return "請求失敗（\(statusCode)）"
        case .decodingError(let error): return "資料解析錯誤: \(error.localizedDescription)"
        case .unauthorized: return "登入已過期，請重新登入"
        case .networkError(let error): return error.localizedDescription
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "請求過於頻繁，請等待 \(seconds) 秒後再試"
            }
            return "請求過於頻繁，請稍後再試"
        case .conflict: return "此時段已被預約，請選擇其他時段"
        case .tokenExpired: return "登入已過期，請重新登入"
        }
    }
}

extension Notification.Name {
    static let authTokenExpired = Notification.Name("authTokenExpired")
}
