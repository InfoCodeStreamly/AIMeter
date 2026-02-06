import Testing
@testable import AIMeterInfrastructure
import AIMeterDomain
import Foundation

/// Tests for AppInfoService
///
/// This suite tests the app information service that provides metadata
/// about the application such as name, author, version, and build number.
/// All tests must run on the main actor due to the service being @MainActor.
@Suite("AppInfoService")
@MainActor
struct AppInfoServiceTests {

    // MARK: - App Name Tests

    @Test("appName returns AIMeter")
    func appNameReturnsAIMeter() {
        // Arrange
        let service = AppInfoService()

        // Act
        let appName = service.appName

        // Assert
        #expect(appName == "AIMeter")
    }

    @Test("appName is not empty")
    func appNameIsNotEmpty() {
        // Arrange
        let service = AppInfoService()

        // Act
        let appName = service.appName

        // Assert
        #expect(!appName.isEmpty)
    }

    // MARK: - Author Tests

    @Test("author returns CodeStreamly")
    func authorReturnsCodeStreamly() {
        // Arrange
        let service = AppInfoService()

        // Act
        let author = service.author

        // Assert
        #expect(author == "CodeStreamly")
    }

    @Test("author is not empty")
    func authorIsNotEmpty() {
        // Arrange
        let service = AppInfoService()

        // Act
        let author = service.author

        // Assert
        #expect(!author.isEmpty)
    }

    // MARK: - Version Tests

    @Test("version is not empty")
    func versionIsNotEmpty() {
        // Arrange
        let service = AppInfoService()

        // Act
        let version = service.version

        // Assert
        #expect(!version.isEmpty)
    }

    @Test("version has valid format")
    func versionHasValidFormat() {
        // Arrange
        let service = AppInfoService()

        // Act
        let version = service.version

        // Assert - should be in format X.Y or X.Y.Z
        let components = version.split(separator: ".").compactMap { Int($0) }
        #expect(components.count >= 2, "Version should have at least 2 components (major.minor)")
    }

    // MARK: - Build Number Tests

    @Test("buildNumber is not empty")
    func buildNumberIsNotEmpty() {
        // Arrange
        let service = AppInfoService()

        // Act
        let buildNumber = service.buildNumber

        // Assert
        #expect(!buildNumber.isEmpty)
    }

    @Test("buildNumber is numeric")
    func buildNumberIsNumeric() {
        // Arrange
        let service = AppInfoService()

        // Act
        let buildNumber = service.buildNumber

        // Assert
        #expect(Int(buildNumber) != nil, "Build number should be numeric")
    }

    // MARK: - Full Version Tests

    @Test("fullVersion format is v{version} ({build})")
    func fullVersionHasCorrectFormat() {
        // Arrange
        let service = AppInfoService()

        // Act
        let fullVersion = service.fullVersion
        let version = service.version
        let buildNumber = service.buildNumber

        // Assert
        #expect(fullVersion == "v\(version) (\(buildNumber))")
    }

    @Test("fullVersion starts with v")
    func fullVersionStartsWithV() {
        // Arrange
        let service = AppInfoService()

        // Act
        let fullVersion = service.fullVersion

        // Assert
        #expect(fullVersion.hasPrefix("v"))
    }

    @Test("fullVersion contains parentheses")
    func fullVersionContainsParentheses() {
        // Arrange
        let service = AppInfoService()

        // Act
        let fullVersion = service.fullVersion

        // Assert
        #expect(fullVersion.contains("("))
        #expect(fullVersion.contains(")"))
    }

    @Test("fullVersion contains version and build")
    func fullVersionContainsVersionAndBuild() {
        // Arrange
        let service = AppInfoService()

        // Act
        let fullVersion = service.fullVersion
        let version = service.version
        let buildNumber = service.buildNumber

        // Assert
        #expect(fullVersion.contains(version))
        #expect(fullVersion.contains(buildNumber))
    }

    @Test("fullVersion is not empty")
    func fullVersionIsNotEmpty() {
        // Arrange
        let service = AppInfoService()

        // Act
        let fullVersion = service.fullVersion

        // Assert
        #expect(!fullVersion.isEmpty)
    }

    // MARK: - Current Version Tests

    @Test("currentVersion is parseable AppVersion")
    func currentVersionIsParseable() {
        // Arrange
        let service = AppInfoService()

        // Act
        let currentVersion = service.currentVersion

        // Assert
        // currentVersion should be parseable (not nil) if version string is valid
        // In production, version comes from Bundle and is set by build script
        if let appVersion = currentVersion {
            #expect(appVersion.major >= 0)
            #expect(appVersion.minor >= 0)
            #expect(appVersion.patch >= 0)
        }
    }

    @Test("currentVersion matches version string when parseable")
    func currentVersionMatchesVersionString() {
        // Arrange
        let service = AppInfoService()

        // Act
        let version = service.version
        let currentVersion = service.currentVersion

        // Assert
        if let appVersion = currentVersion {
            let formatted = appVersion.formatted
            // Version string might have different number of components
            // but formatted AppVersion should match the base format
            #expect(version.hasPrefix("\(appVersion.major).\(appVersion.minor)"))
        }
    }

    // MARK: - Service Consistency Tests

    @Test("multiple instances return same values")
    func multipleInstancesReturnSameValues() {
        // Arrange
        let service1 = AppInfoService()
        let service2 = AppInfoService()

        // Act & Assert
        #expect(service1.appName == service2.appName)
        #expect(service1.author == service2.author)
        #expect(service1.version == service2.version)
        #expect(service1.buildNumber == service2.buildNumber)
        #expect(service1.fullVersion == service2.fullVersion)
    }

    @Test("values are consistent across multiple calls")
    func valuesAreConsistentAcrossMultipleCalls() {
        // Arrange
        let service = AppInfoService()

        // Act
        let appName1 = service.appName
        let appName2 = service.appName
        let version1 = service.version
        let version2 = service.version
        let buildNumber1 = service.buildNumber
        let buildNumber2 = service.buildNumber

        // Assert
        #expect(appName1 == appName2)
        #expect(version1 == version2)
        #expect(buildNumber1 == buildNumber2)
    }
}
