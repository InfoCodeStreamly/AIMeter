import Testing
import SwiftUI
@testable import AIMeterPresentation
@testable import AIMeterDomain

@Suite("AppTheme+UI")
struct AppThemeUITests {

    @Test("colorScheme mapping is correct")
    func colorSchemeMapping() {
        #expect(AppTheme.system.colorScheme == nil)
        #expect(AppTheme.light.colorScheme == .light)
        #expect(AppTheme.dark.colorScheme == .dark)
    }

    @Test("icon is non-empty for all themes")
    func iconNonEmpty() {
        for theme in AppTheme.allCases {
            #expect(!theme.icon.isEmpty)
        }
    }

    @Test("system theme icon is gear")
    func systemIcon() {
        #expect(AppTheme.system.icon == "gear")
    }

    @Test("light theme icon is sun.max")
    func lightIcon() {
        #expect(AppTheme.light.icon == "sun.max")
    }

    @Test("dark theme icon is moon")
    func darkIcon() {
        #expect(AppTheme.dark.icon == "moon")
    }
}
