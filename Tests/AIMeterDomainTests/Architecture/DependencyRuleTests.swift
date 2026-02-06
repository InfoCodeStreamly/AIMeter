import Testing
import Foundation

/// Architecture tests verifying Clean Architecture dependency rules
/// Domain → (nothing)
/// Application → Domain
/// Infrastructure → Domain, Application
/// Presentation → Domain, Application (should NOT import Infrastructure directly)
@Suite("Clean Architecture Dependency Rules")
struct DependencyRuleTests {

    private let projectRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // Architecture/
        .deletingLastPathComponent() // AIMeterDomainTests/
        .deletingLastPathComponent() // Tests/
        .deletingLastPathComponent() // AIMeter project root

    // MARK: - Domain Layer

    @Test("Domain layer does not import Application")
    func domainDoesNotImportApplication() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterDomain",
            forbiddenImports: ["AIMeterApplication"]
        )
        #expect(violations.isEmpty, "Domain must not import Application: \(violations)")
    }

    @Test("Domain layer does not import Infrastructure")
    func domainDoesNotImportInfrastructure() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterDomain",
            forbiddenImports: ["AIMeterInfrastructure"]
        )
        #expect(violations.isEmpty, "Domain must not import Infrastructure: \(violations)")
    }

    @Test("Domain layer does not import Presentation")
    func domainDoesNotImportPresentation() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterDomain",
            forbiddenImports: ["AIMeterPresentation"]
        )
        #expect(violations.isEmpty, "Domain must not import Presentation: \(violations)")
    }

    // MARK: - Application Layer

    @Test("Application layer does not import Infrastructure")
    func applicationDoesNotImportInfrastructure() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterApplication",
            forbiddenImports: ["AIMeterInfrastructure"]
        )
        #expect(violations.isEmpty, "Application must not import Infrastructure: \(violations)")
    }

    @Test("Application layer does not import Presentation")
    func applicationDoesNotImportPresentation() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterApplication",
            forbiddenImports: ["AIMeterPresentation"]
        )
        #expect(violations.isEmpty, "Application must not import Presentation: \(violations)")
    }

    // MARK: - Infrastructure Layer

    @Test("Infrastructure layer does not import Presentation")
    func infrastructureDoesNotImportPresentation() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterInfrastructure",
            forbiddenImports: ["AIMeterPresentation"]
        )
        #expect(violations.isEmpty, "Infrastructure must not import Presentation: \(violations)")
    }

    // MARK: - Helpers

    private func findImportViolations(
        in directory: String,
        forbiddenImports: [String]
    ) throws -> [String] {
        let dirURL = projectRoot.appendingPathComponent(directory)
        var violations: [String] = []

        let enumerator = FileManager.default.enumerator(
            at: dirURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.pathExtension == "swift" else { continue }

            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)

            for (lineNumber, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                // Skip comments
                guard !trimmed.hasPrefix("//"), !trimmed.hasPrefix("*") else { continue }

                for forbidden in forbiddenImports {
                    if trimmed == "import \(forbidden)" ||
                       trimmed == "@testable import \(forbidden)" {
                        let fileName = fileURL.lastPathComponent
                        violations.append("\(fileName):\(lineNumber + 1) imports \(forbidden)")
                    }
                }
            }
        }

        return violations
    }
}
