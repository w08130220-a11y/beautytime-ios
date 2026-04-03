import Foundation

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: configuration)

        self.encoder = JSONEncoder()
        // 不轉 snake_case，後端接受 camelCase keys

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let isoWithFrac = ISO8601DateFormatter()
            isoWithFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoWithFrac.date(from: dateString) { return date }
            let isoWithout = ISO8601DateFormatter()
            isoWithout.formatOptions = [.withInternetDateTime]
            if let date = isoWithout.date(from: dateString) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        path: String,
        method: HTTPMethod,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let data = try await performRequest(path: path, method: method, body: body, queryItems: queryItems)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Convenience Methods

    func get<T: Decodable>(path: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        try await request(path: path, method: .GET, queryItems: queryItems)
    }

    func post<T: Decodable>(path: String, body: (any Encodable)? = nil) async throws -> T {
        try await request(path: path, method: .POST, body: body)
    }

    func patch<T: Decodable>(path: String, body: (any Encodable)? = nil) async throws -> T {
        try await request(path: path, method: .PATCH, body: body)
    }

    func put<T: Decodable>(path: String, body: (any Encodable)? = nil) async throws -> T {
        try await request(path: path, method: .PUT, body: body)
    }

    func delete(path: String) async throws {
        _ = try await performRequest(path: path, method: .DELETE)
    }

    // MARK: - Private

    private let maxRetries = 3

    private func performRequest(
        path: String,
        method: HTTPMethod,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> Data {
        var components = URLComponents(string: AppConfig.apiBaseURL + path)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Check token expiry before making request
        if TokenManager.shared.isTokenExpired() {
            TokenManager.shared.deleteToken()
            NotificationCenter.default.post(name: .authTokenExpired, object: nil)
            throw APIError.tokenExpired
        }

        if let token = TokenManager.shared.getToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
            #if DEBUG
            if let bodyData = urlRequest.httpBody {
                print("[API] \(method.rawValue) \(path) body: \(String(data: bodyData, encoding: .utf8) ?? "nil")")
            }
            #endif
        }

        // Retry logic: only for GET requests (idempotent)
        let isRetryable = method == .GET
        var lastError: Error = APIError.invalidResponse

        for attempt in 0..<(isRetryable ? maxRetries : 1) {
            if attempt > 0 {
                let delay = UInt64(pow(2.0, Double(attempt - 1))) * 1_000_000_000
                try await Task.sleep(nanoseconds: delay)
                #if DEBUG
                print("[API] Retry \(attempt)/\(maxRetries) for \(path)")
                #endif
            }

            let data: Data
            let response: URLResponse

            do {
                (data, response) = try await session.data(for: urlRequest)
            } catch {
                lastError = APIError.networkError(error)
                if isRetryable { continue }
                throw lastError
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            #if DEBUG
            print("[API] \(method.rawValue) \(path) → \(httpResponse.statusCode) \(String(data: data.prefix(500), encoding: .utf8) ?? "")")
            #endif

            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   json["message"] != nil {
                    throw APIError.httpError(statusCode: 401, data: data)
                }
                TokenManager.shared.deleteToken()
                NotificationCenter.default.post(name: .authTokenExpired, object: nil)
                throw APIError.unauthorized
            case 409:
                throw APIError.conflict
            case 429:
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                    .flatMap { Int($0) }
                throw APIError.rateLimited(retryAfter: retryAfter)
            case 500...599:
                lastError = APIError.httpError(statusCode: httpResponse.statusCode, data: data)
                if isRetryable { continue }
                throw lastError
            default:
                throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
            }
        }

        throw lastError
    }
}

// MARK: - AnyEncodable Wrapper

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        self.encodeClosure = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

// MARK: - JSON Body Helper

/// A flexible JSON body that can hold mixed types (String, Int, Double, Bool, etc.)
/// Use this instead of [String: Any] which doesn't conform to Encodable.
struct JSONBody: Encodable {
    private var storage: [String: JSONValue] = [:]

    init(_ dictionary: [String: Any]) {
        for (key, value) in dictionary {
            storage[key] = JSONValue(value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        for (key, value) in storage {
            let codingKey = DynamicCodingKey(stringValue: key)!
            try container.encode(value, forKey: codingKey)
        }
    }
}

private enum JSONValue: Encodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSONValue])
    case dictionary([String: JSONValue])
    case null

    init(_ value: Any) {
        switch value {
        case let v as String: self = .string(v)
        case let v as Int: self = .int(v)
        case let v as Double: self = .double(v)
        case let v as Bool: self = .bool(v)
        case let v as [Any]: self = .array(v.map { JSONValue($0) })
        case let v as [String: Any]: self = .dictionary(v.mapValues { JSONValue($0) })
        default: self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .dictionary(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.stringValue = "\(intValue)"; self.intValue = intValue }
}
