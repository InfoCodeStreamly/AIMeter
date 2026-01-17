import Foundation

/// Result of update check
enum UpdateCheckResult: Sendable {
    case upToDate
    case updateAvailable(version: String, url: URL)
    case error(String)
}

/// Use case for checking app updates via GitHub Releases
@MainActor
final class CheckForUpdatesUseCase {
    private let appInfoService: AppInfoService
    private let gitHubUpdateService: GitHubUpdateService

    init(appInfoService: AppInfoService, gitHubUpdateService: GitHubUpdateService) {
        self.appInfoService = appInfoService
        self.gitHubUpdateService = gitHubUpdateService
    }

    /// Check for updates by comparing local version with latest GitHub release
    /// - Returns: UpdateCheckResult indicating if update is available
    func execute() async -> UpdateCheckResult {
        guard let currentVersion = appInfoService.currentVersion else {
            return .error("Cannot determine current version")
        }

        do {
            guard let release = try await gitHubUpdateService.checkLatestRelease() else {
                return .upToDate
            }

            guard let latestVersion = AppVersion.parse(release.tagName) else {
                return .error("Invalid release version format")
            }

            if latestVersion > currentVersion {
                guard let url = URL(string: release.htmlUrl) else {
                    return .error("Invalid release URL")
                }
                return .updateAvailable(version: latestVersion.formatted, url: url)
            }

            return .upToDate
        } catch {
            return .error(error.localizedDescription)
        }
    }
}
