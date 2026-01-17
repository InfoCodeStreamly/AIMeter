import Foundation
import OSLog

/// GitHub release data
struct GitHubRelease: Sendable, Codable {
    let tagName: String
    let htmlUrl: String
    let publishedAt: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
    }
}

/// Service for checking GitHub releases
actor GitHubUpdateService {
    private var lastCheckTime: Date?
    private var cachedRelease: GitHubRelease?
    private let cacheInterval: TimeInterval = 3600 // 1 hour

    /// Check latest release from GitHub API
    /// - Returns: Latest GitHubRelease if available
    func checkLatestRelease() async throws -> GitHubRelease? {
        // Return cached result if within cache interval
        if let lastCheck = lastCheckTime,
           let cached = cachedRelease,
           Date().timeIntervalSince(lastCheck) < cacheInterval {
            Logger.updates.debug("Returning cached release: \(cached.tagName)")
            return cached
        }

        let urlString = "\(APIConstants.GitHub.apiBaseURL)/repos/\(APIConstants.GitHub.repoOwner)/\(APIConstants.GitHub.repoName)/releases/latest"

        guard let url = URL(string: urlString) else {
            Logger.updates.error("Invalid GitHub API URL")
            throw UpdateError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(APIConstants.Headers.applicationJSON, forHTTPHeaderField: APIConstants.Headers.accept)
        request.setValue(APIConstants.Headers.appUserAgent, forHTTPHeaderField: APIConstants.Headers.userAgent)

        Logger.updates.info("Checking for updates at: \(urlString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.invalidResponse
        }

        // 404 means no releases yet
        if httpResponse.statusCode == 404 {
            Logger.updates.info("No releases found")
            return nil
        }

        guard httpResponse.statusCode == 200 else {
            Logger.updates.error("GitHub API error: \(httpResponse.statusCode)")
            throw UpdateError.httpError(httpResponse.statusCode)
        }

        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

        // Cache result
        lastCheckTime = Date()
        cachedRelease = release

        Logger.updates.info("Latest release: \(release.tagName)")
        return release
    }

    /// Clear cached release data
    func clearCache() {
        lastCheckTime = nil
        cachedRelease = nil
    }
}

/// Update-related errors
enum UpdateError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid GitHub URL"
        case .invalidResponse:
            return "Invalid response from GitHub"
        case .httpError(let code):
            return "GitHub API error (code: \(code))"
        }
    }
}
