import Testing
import Foundation
@testable import AIMeterInfrastructure
@testable import AIMeterDomain

@Suite("ThemeService")
struct ThemeServiceTests {

    @Test("Default theme is system")
    @MainActor
    func defaultThemeIsSystem() {
        // Clean up any saved state
        UserDefaults.standard.removeObject(forKey: "selectedTheme")

        let service = ThemeService()
        #expect(service.selectedTheme == .system)
    }

    @Test("Changing theme persists to UserDefaults")
    @MainActor
    func changingThemePersists() {
        UserDefaults.standard.removeObject(forKey: "selectedTheme")

        let service = ThemeService()
        service.selectedTheme = .dark

        let saved = UserDefaults.standard.string(forKey: "selectedTheme")
        #expect(saved == "dark")

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
    }

    @Test("Loads saved theme on init")
    @MainActor
    func loadsSavedTheme() {
        UserDefaults.standard.set("light", forKey: "selectedTheme")

        let service = ThemeService()
        #expect(service.selectedTheme == .light)

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
    }

    @Test("Invalid saved value falls back to system")
    @MainActor
    func invalidSavedValueFallsBack() {
        UserDefaults.standard.set("invalid", forKey: "selectedTheme")

        let service = ThemeService()
        #expect(service.selectedTheme == .system)

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
    }
}
