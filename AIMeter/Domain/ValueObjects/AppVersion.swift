import Foundation

/// Semantic version representation for app updates
struct AppVersion: Sendable, Comparable, Equatable {
    let major: Int
    let minor: Int
    let patch: Int

    /// Formatted version string (e.g., "1.0.0")
    var formatted: String { "\(major).\(minor).\(patch)" }

    /// Parse version from string (e.g., "1.0.0" or "v1.0.0")
    /// - Parameter string: Version string to parse
    /// - Returns: AppVersion if parsing succeeds, nil otherwise
    static func parse(_ string: String) -> AppVersion? {
        // Remove 'v' prefix if present
        let cleaned = string.hasPrefix("v") ? String(string.dropFirst()) : string

        let components = cleaned.split(separator: ".").compactMap { Int($0) }

        guard components.count >= 2 else { return nil }

        return AppVersion(
            major: components[0],
            minor: components[1],
            patch: components.count > 2 ? components[2] : 0
        )
    }

    /// Compare versions for sorting
    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}
