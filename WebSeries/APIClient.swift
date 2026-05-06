import Foundation

struct APIClient {

    static func request(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        token: String? = nil
    ) async throws -> Data {

        guard let url = URL(string: ServerConfig.apiBaseURL + endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // 🔍 LOG REQUEST
        debugLog("➡️ \(method) \(url.absoluteString)")
        if let token {
            let prefix = String(token.prefix(12))
            debugLog("🔐 Authorization: Bearer \(prefix)...")
        } else {
            debugLog("🔐 Authorization: none")
        }
        if let body {
            debugLog("📤 BODY:", String(data: body, encoding: .utf8) ?? "nil")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // 🔍 LOG RESPONSE
        debugLog("⬅️ STATUS:", http.statusCode)
        debugLog("📥 RESPONSE:", String(data: data, encoding: .utf8) ?? "nil")

        if http.statusCode >= 400 {
            let message = String(data: data, encoding: .utf8) ?? "Error servidor"
            throw APIError.server(message)
        }

        return data
    }
}

enum APIError: Error, LocalizedError {
    case server(String)

    var errorDescription: String? {
        switch self {
        case .server(let message):
            return message
        }
    }
}
