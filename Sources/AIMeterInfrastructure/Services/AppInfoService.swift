import AIMeterApplication
import AIMeterDomain
import Foundation

/// Service for accessing app bundle information (Infrastructure)
@MainActor
public final class AppInfoService: AppInfoServiceProtocol {
    public init() {}

    public var appName: String { "AIMeter" }
    public var author: String { "CodeStreamly" }

    public var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    public var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    public var fullVersion: String { "v\(version) (\(buildNumber))" }
    public var currentVersion: AppVersion? { AppVersion.parse(version) }
}
