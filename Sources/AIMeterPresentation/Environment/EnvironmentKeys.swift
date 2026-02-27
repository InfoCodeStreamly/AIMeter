import AIMeterApplication
import SwiftUI

// MARK: - ThemeService

struct ThemeServiceKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any ThemeServiceProtocol)? = nil
}

// MARK: - LanguageService

struct LanguageServiceKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any LanguageServiceProtocol)? = nil
}

// MARK: - NotificationPreferences

struct NotificationPreferencesKey: EnvironmentKey {
    static let defaultValue: (any NotificationPreferencesProtocol)? = nil
}

public extension EnvironmentValues {
    var themeService: (any ThemeServiceProtocol)? {
        get { self[ThemeServiceKey.self] }
        set { self[ThemeServiceKey.self] = newValue }
    }

    var languageService: (any LanguageServiceProtocol)? {
        get { self[LanguageServiceKey.self] }
        set { self[LanguageServiceKey.self] = newValue }
    }

    var notificationPreferences: (any NotificationPreferencesProtocol)? {
        get { self[NotificationPreferencesKey.self] }
        set { self[NotificationPreferencesKey.self] = newValue }
    }
}
