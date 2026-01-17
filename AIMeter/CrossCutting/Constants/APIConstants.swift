import Foundation

/// API-related constants
enum APIConstants {
    /// Claude API base URL
    static let baseURL = "https://claude.ai/api"

    /// Default request timeout in seconds
    static let timeout: TimeInterval = 30

    /// Auto-refresh interval in seconds
    static let refreshInterval: TimeInterval = 60

    /// Maximum retry attempts
    static let maxRetries = 3

    /// Keychain keys
    enum KeychainKeys {
        static let sessionKey = "sessionKey"
        static let organizationId = "organizationId"
    }

    /// HTTP headers
    enum Headers {
        static let contentType = "Content-Type"
        static let accept = "Accept"
        static let cookie = "Cookie"
        static let userAgent = "User-Agent"

        static let applicationJSON = "application/json"
        static let appUserAgent = "AIMeter/1.0"
    }

    /// GitHub API for update checks
    enum GitHub {
        static let apiBaseURL = "https://api.github.com"
        static let repoOwner = "InfoCodeStreamly"
        static let repoName = "AIMeter"
        static let repoURL = "https://github.com/\(repoOwner)/\(repoName)"
    }

    /// OAuth configuration
    enum OAuth {
        /// Anthropic OAuth token endpoint
        static let tokenURL = "https://console.anthropic.com/v1/oauth/token"

        /// Claude Code OAuth client ID
        static let clientId = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"

        /// Proactive refresh threshold (refresh if less than 5 minutes remaining)
        static let refreshThresholdSeconds: TimeInterval = 5 * 60

        /// Token refresh retry delay
        static let refreshRetryDelay: TimeInterval = 5
    }
}
