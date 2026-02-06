import Testing
@testable import AIMeterDomain

@Suite("AppVersion")
struct AppVersionTests {

    // MARK: - Parse Tests

    @Test("parse valid three-component version")
    func parseThreeComponent() {
        let version = AppVersion.parse("1.2.3")
        #expect(version != nil)
        #expect(version?.major == 1)
        #expect(version?.minor == 2)
        #expect(version?.patch == 3)
    }

    @Test("parse valid two-component version")
    func parseTwoComponent() {
        let version = AppVersion.parse("1.2")
        #expect(version != nil)
        #expect(version?.major == 1)
        #expect(version?.minor == 2)
        #expect(version?.patch == 0)
    }

    @Test("parse with v prefix")
    func parseWithVPrefix() {
        let version = AppVersion.parse("v1.2.3")
        #expect(version != nil)
        #expect(version?.major == 1)
        #expect(version?.minor == 2)
        #expect(version?.patch == 3)
    }

    @Test("parse with uppercase V prefix")
    func parseWithUppercaseVPrefix() {
        let version = AppVersion.parse("V1.2.3")
        #expect(version != nil)
        #expect(version?.major == 1)
        #expect(version?.minor == 2)
        #expect(version?.patch == 3)
    }

    @Test("parse single component version returns nil")
    func parseSingleComponent() {
        // Requires at least 2 components
        let version = AppVersion.parse("5")
        #expect(version == nil)
    }

    @Test("parse returns nil for invalid string")
    func parseInvalid() {
        let version = AppVersion.parse("not a version")
        #expect(version == nil)
    }

    @Test("parse returns nil for empty string")
    func parseEmpty() {
        let version = AppVersion.parse("")
        #expect(version == nil)
    }

    @Test("parse filters out non-numeric components via compactMap")
    func parseNonNumeric() {
        // "1.x.3" -> split ["1","x","3"] -> compactMap [1,3] -> AppVersion(1,3,0)
        let version = AppVersion.parse("1.x.3")
        #expect(version != nil)
        #expect(version?.major == 1)
        #expect(version?.minor == 3)
        #expect(version?.patch == 0)
    }

    @Test("parse with leading zeros")
    func parseLeadingZeros() {
        let version = AppVersion.parse("01.02.03")
        #expect(version != nil)
        #expect(version?.major == 1)
        #expect(version?.minor == 2)
        #expect(version?.patch == 3)
    }

    @Test("parse with whitespace trims and parses correctly")
    func parseWithWhitespace() {
        let version = AppVersion.parse("  1.2.3  ")
        #expect(version != nil)
        #expect(version?.major == 1)
        #expect(version?.minor == 2)
        #expect(version?.patch == 3)
    }

    // MARK: - Formatted Tests

    @Test("formatted displays three components")
    func formattedThreeComponent() {
        let version = AppVersion.parse("1.2.3")!
        #expect(version.formatted == "1.2.3")
    }

    @Test("formatted displays zeros")
    func formattedZeros() {
        let version = AppVersion.parse("1.0.0")!
        #expect(version.formatted == "1.0.0")
    }

    @Test("formatted displays large numbers")
    func formattedLarge() {
        let version = AppVersion.parse("10.20.30")!
        #expect(version.formatted == "10.20.30")
    }

    // MARK: - Comparison Tests

    @Test("compare major version difference")
    func compareMajor() {
        let v1 = AppVersion.parse("1.0.0")!
        let v2 = AppVersion.parse("2.0.0")!
        #expect(v1 < v2)
        #expect(v2 > v1)
    }

    @Test("compare minor version difference")
    func compareMinor() {
        let v1 = AppVersion.parse("1.0.0")!
        let v2 = AppVersion.parse("1.1.0")!
        #expect(v1 < v2)
        #expect(v2 > v1)
    }

    @Test("compare patch version difference")
    func comparePatch() {
        let v1 = AppVersion.parse("1.0.0")!
        let v2 = AppVersion.parse("1.0.1")!
        #expect(v1 < v2)
        #expect(v2 > v1)
    }

    @Test("compare equal versions")
    func compareEqual() {
        let v1 = AppVersion.parse("1.2.3")!
        let v2 = AppVersion.parse("1.2.3")!
        #expect(!(v1 < v2))
        #expect(!(v1 > v2))
        #expect(v1 == v2)
    }

    @Test("compare with v prefix ignored")
    func compareVPrefix() {
        let v1 = AppVersion.parse("v1.2.3")!
        let v2 = AppVersion.parse("1.2.3")!
        #expect(v1 == v2)
    }

    @Test("compare complex scenario")
    func compareComplex() {
        let v1 = AppVersion.parse("1.9.9")!
        let v2 = AppVersion.parse("2.0.0")!
        #expect(v1 < v2)
    }

    @Test("compare three-way")
    func compareThreeWay() {
        let v1 = AppVersion.parse("1.0.0")!
        let v2 = AppVersion.parse("1.5.0")!
        let v3 = AppVersion.parse("2.0.0")!

        #expect(v1 < v2)
        #expect(v2 < v3)
        #expect(v1 < v3)
    }

    // MARK: - Equatable Tests

    @Test("equatable for identical versions")
    func equatableIdentical() {
        let v1 = AppVersion.parse("1.2.3")!
        let v2 = AppVersion.parse("1.2.3")!
        #expect(v1 == v2)
    }

    @Test("equatable for different versions")
    func equatableDifferent() {
        let v1 = AppVersion.parse("1.2.3")!
        let v2 = AppVersion.parse("1.2.4")!
        #expect(v1 != v2)
    }

    @Test("equatable with implicit patch")
    func equatableImplicitPatch() {
        let v1 = AppVersion.parse("1.2")!
        let v2 = AppVersion.parse("1.2.0")!
        #expect(v1 == v2)
    }

    // MARK: - Edge Cases

    @Test("parse version with extra text filters non-numeric via compactMap")
    func parseExtraText() {
        // "1.2.3-beta" -> split ["1","2","3-beta"] -> compactMap: Int("3-beta")=nil -> [1,2]
        // count 2 >= 2 -> AppVersion(1, 2, 0)
        let version = AppVersion.parse("1.2.3-beta")
        #expect(version != nil)
        #expect(version?.major == 1)
        #expect(version?.minor == 2)
        #expect(version?.patch == 0)
    }

    @Test("parse version with four components ignores extra")
    func parseFourComponents() {
        // "1.2.3.4" -> compactMap [1,2,3,4], takes first 3
        let version = AppVersion.parse("1.2.3.4")
        #expect(version != nil)
        #expect(version?.major == 1)
        #expect(version?.minor == 2)
        #expect(version?.patch == 3)
    }

    @Test("parse negative numbers returns nil")
    func parseNegative() {
        let version = AppVersion.parse("-1.2.3")
        #expect(version == nil)
    }

    @Test("compare sorting order")
    func compareSorting() {
        let versions = [
            AppVersion.parse("2.0.0")!,
            AppVersion.parse("1.0.0")!,
            AppVersion.parse("1.5.0")!,
            AppVersion.parse("1.0.1")!
        ]

        let sorted = versions.sorted()

        #expect(sorted[0] == AppVersion.parse("1.0.0")!)
        #expect(sorted[1] == AppVersion.parse("1.0.1")!)
        #expect(sorted[2] == AppVersion.parse("1.5.0")!)
        #expect(sorted[3] == AppVersion.parse("2.0.0")!)
    }
}
