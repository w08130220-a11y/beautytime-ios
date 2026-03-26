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
        case .httpError(_, let data):
            // Try to parse API error message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // message can be String or [String]
                if let message = json["message"] as? String {
                    return message
                }
                if let messages = json["message"] as? [String], let first = messages.first {
                    return first
                }
            }
            return "伺服器錯誤"
        case .decodingError(let error): return "資料解析錯誤: \(error.localizedDescription)"
        case .unauthorized: return "登入已過期，請重新登入"
        case .networkError(let error): return error.localizedDescription
        }
    }
}
