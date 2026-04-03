import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case unauthorized
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無效的網址"
        case .invalidResponse: return "無效的回應"
        case .httpError(let statusCode, let data):
            // 5xx 伺服器錯誤 → 顯示友善訊息，不暴露後端細節
            if statusCode >= 500 {
                return "伺服器暫時無法處理請求，請稍後再試"
            }
            // 4xx 客戶端錯誤 → 嘗試解析 API 回傳的 message
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
        }
    }
}
