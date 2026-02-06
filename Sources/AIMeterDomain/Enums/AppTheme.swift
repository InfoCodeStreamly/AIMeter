import Foundation

/// Supported app appearance themes
public enum AppTheme: String, CaseIterable, Codable, Sendable {
    case system = "system"
    case light = "light"
    case dark = "dark"
}
