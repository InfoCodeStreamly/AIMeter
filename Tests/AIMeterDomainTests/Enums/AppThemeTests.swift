import Testing
import Foundation
@testable import AIMeterDomain

@Suite("AppTheme")
struct AppThemeTests {

    @Test("rawValue mapping is correct")
    func rawValueMapping() {
        #expect(AppTheme.system.rawValue == "system")
        #expect(AppTheme.light.rawValue == "light")
        #expect(AppTheme.dark.rawValue == "dark")
    }

    @Test("allCases contains exactly 3 themes")
    func allCasesCount() {
        #expect(AppTheme.allCases.count == 3)
        #expect(AppTheme.allCases.contains(.system))
        #expect(AppTheme.allCases.contains(.light))
        #expect(AppTheme.allCases.contains(.dark))
    }

    @Test("init from rawValue succeeds for valid values")
    func initFromRawValue() {
        #expect(AppTheme(rawValue: "system") == .system)
        #expect(AppTheme(rawValue: "light") == .light)
        #expect(AppTheme(rawValue: "dark") == .dark)
    }

    @Test("init from rawValue returns nil for invalid values")
    func initFromInvalidRawValue() {
        #expect(AppTheme(rawValue: "auto") == nil)
        #expect(AppTheme(rawValue: "") == nil)
        #expect(AppTheme(rawValue: "Dark") == nil)
    }

    @Test("Codable encode and decode round-trips correctly")
    func codableRoundTrip() throws {
        for theme in AppTheme.allCases {
            let data = try JSONEncoder().encode(theme)
            let decoded = try JSONDecoder().decode(AppTheme.self, from: data)
            #expect(decoded == theme)
        }
    }

    @Test("Codable decodes from JSON string")
    func codableFromJSON() throws {
        let json = Data("\"dark\"".utf8)
        let theme = try JSONDecoder().decode(AppTheme.self, from: json)
        #expect(theme == .dark)
    }
}
