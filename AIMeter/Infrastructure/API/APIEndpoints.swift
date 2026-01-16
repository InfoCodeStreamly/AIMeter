import Foundation

/// Claude API endpoints configuration
/// Supports two authentication methods:
/// 1. OAuth token (sk-ant-oat...) - uses api.anthropic.com
/// 2. Session key (sk-ant-sid...) - uses claude.ai/api
enum APIEndpoints {

    // MARK: - Base URLs

    /// OAuth API base (for Claude Code CLI tokens)
    static let oauthBaseURL = "https://api.anthropic.com/api/oauth"

    /// Claude.ai API base (for browser session keys)
    static let claudeBaseURL = "https://claude.ai/api"

    // MARK: - Auth Type Detection

    /// Detects if key is OAuth token (from Claude Code CLI)
    static func isOAuthToken(_ key: String) -> Bool {
        key.hasPrefix("sk-ant-oat")
    }

    // MARK: - Usage Endpoints

    /// OAuth usage endpoint (no org ID needed)
    static var oauthUsage: URL {
        URL(string: "\(oauthBaseURL)/usage")!
    }

    /// Claude.ai usage endpoint (requires org ID)
    static func claudeUsage(organizationId: String) -> URL {
        URL(string: "\(claudeBaseURL)/organizations/\(organizationId)/usage")!
    }

    // MARK: - Organizations Endpoint (only for session key auth)

    static var organizations: URL {
        URL(string: "\(claudeBaseURL)/organizations")!
    }

    // MARK: - Headers

    /// Headers for OAuth API (api.anthropic.com)
    static func oauthHeaders(token: String) -> [String: String] {
        [
            "Authorization": "Bearer \(token)",
            "anthropic-beta": "oauth-2025-04-20",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "AIMeter/1.0"
        ]
    }

    /// Headers for Claude.ai API (session key cookie)
    static func claudeHeaders(sessionKey: String) -> [String: String] {
        [
            "Cookie": "sessionKey=\(sessionKey)",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "AIMeter/1.0"
        ]
    }

    /// Auto-detect and return appropriate headers
    static func headers(sessionKey: String) -> [String: String] {
        if isOAuthToken(sessionKey) {
            return oauthHeaders(token: sessionKey)
        } else {
            return claudeHeaders(sessionKey: sessionKey)
        }
    }
}
