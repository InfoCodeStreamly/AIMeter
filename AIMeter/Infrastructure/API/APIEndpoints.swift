import Foundation

/// Claude API endpoints configuration (OAuth only)
/// Uses Claude Code CLI OAuth tokens (sk-ant-oat...)
enum APIEndpoints {

    // MARK: - Base URL

    /// OAuth API base URL
    static let baseURL = "https://api.anthropic.com/api/oauth"

    // MARK: - Endpoints

    /// Usage endpoint
    static var usage: URL {
        URL(string: "\(baseURL)/usage")!
    }

    // MARK: - Headers

    /// OAuth API headers
    static func headers(token: String) -> [String: String] {
        [
            "Authorization": "Bearer \(token)",
            "anthropic-beta": "oauth-2025-04-20",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "AIMeter/1.0"
        ]
    }
}
