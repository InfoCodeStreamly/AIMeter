import Foundation

/// API-related constants (Infrastructure layer configuration)
public enum APIConstants {
    public static let baseURL = "https://claude.ai/api"
    public static let timeout: TimeInterval = 30
    public static let refreshInterval: TimeInterval = 60
    public static let maxRetries = 3

    public enum KeychainKeys {
        public static let sessionKey = "sessionKey"
        public static let organizationId = "organizationId"
    }

    public enum Headers {
        public static let contentType = "Content-Type"
        public static let accept = "Accept"
        public static let cookie = "Cookie"
        public static let userAgent = "User-Agent"
        public static let applicationJSON = "application/json"
        public static let appUserAgent = "AIMeter/1.0"
    }

    public enum GitHub {
        public static let apiBaseURL = "https://api.github.com"
        public static let repoOwner = "InfoCodeStreamly"
        public static let repoName = "AIMeter"
        public static let repoURL = "https://github.com/\(repoOwner)/\(repoName)"
    }

    public enum OAuth {
        public static let tokenURL = "https://console.anthropic.com/v1/oauth/token"
        public static let clientId = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
        public static let refreshThresholdSeconds: TimeInterval = 5 * 60
        public static let refreshRetryDelay: TimeInterval = 5
    }
}
