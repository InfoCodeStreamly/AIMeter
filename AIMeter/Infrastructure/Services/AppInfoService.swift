import Foundation

/// Service for accessing app bundle information
@MainActor
final class AppInfoService {
    /// App name
    var appName: String { "AIMeter" }

    /// Author/company name
    var author: String { "CodeStreamly" }

    /// Version from bundle (e.g., "1.0.0")
    var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// Build number from bundle (e.g., "1")
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Full version string (e.g., "v1.0.0 (1)")
    var fullVersion: String { "v\(version) (\(buildNumber))" }

    /// Parsed current version for comparison
    var currentVersion: AppVersion? { AppVersion.parse(version) }
}
