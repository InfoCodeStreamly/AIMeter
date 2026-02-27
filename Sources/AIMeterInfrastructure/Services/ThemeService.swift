import AIMeterApplication
import AIMeterDomain
import Foundation

/// SSOT (Single Source of Truth) for app theme selection
/// Persists user's theme preference
@MainActor
@Observable
public final class ThemeService: ThemeServiceProtocol {
    private let userDefaultsKey = "selectedTheme"

    /// Currently selected theme
    public var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: userDefaultsKey)
        }
    }

    public init() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let theme = AppTheme(rawValue: saved) {
            self.selectedTheme = theme
        } else {
            self.selectedTheme = .system
        }
    }
}
