import Foundation
import Testing

/// Architecture tests verifying Clean Architecture dependency rules.
///
/// Allowed dependencies (→ = "can import"):
///   Domain    → Foundation
///   Application → Foundation, AIMeterDomain
///   Infrastructure → Foundation, AIMeterDomain, AIMeterApplication, SwiftUI, AppKit, OSLog, …
///   Presentation   → Foundation, AIMeterDomain, AIMeterApplication, SwiftUI, AppKit, OSLog, …
///
/// Forbidden:
///   Domain         ✗ Application, Infrastructure, Presentation, SwiftUI, AppKit
///   Application    ✗ Infrastructure, Presentation, SwiftUI, AppKit
///   Infrastructure ✗ Presentation
///   Presentation   ✗ Infrastructure
@Suite("Clean Architecture Dependency Rules")
struct DependencyRuleTests {

    private let projectRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // Architecture/
        .deletingLastPathComponent() // AIMeterDomainTests/
        .deletingLastPathComponent() // Tests/
        .deletingLastPathComponent() // AIMeter project root

    // MARK: - Domain Layer (purest — only Foundation)

    @Test("Domain does not import Application")
    func domainDoesNotImportApplication() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterDomain",
            forbiddenImports: ["AIMeterApplication"]
        )
        #expect(violations.isEmpty, "Domain must not import Application:\n\(formatted(violations))")
    }

    @Test("Domain does not import Infrastructure")
    func domainDoesNotImportInfrastructure() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterDomain",
            forbiddenImports: ["AIMeterInfrastructure"]
        )
        #expect(violations.isEmpty, "Domain must not import Infrastructure:\n\(formatted(violations))")
    }

    @Test("Domain does not import Presentation")
    func domainDoesNotImportPresentation() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterDomain",
            forbiddenImports: ["AIMeterPresentation"]
        )
        #expect(violations.isEmpty, "Domain must not import Presentation:\n\(formatted(violations))")
    }

    @Test("Domain does not import SwiftUI")
    func domainDoesNotImportSwiftUI() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterDomain",
            forbiddenImports: ["SwiftUI"]
        )
        #expect(violations.isEmpty, "Domain must not import SwiftUI:\n\(formatted(violations))")
    }

    @Test("Domain does not import AppKit")
    func domainDoesNotImportAppKit() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterDomain",
            forbiddenImports: ["AppKit"]
        )
        #expect(violations.isEmpty, "Domain must not import AppKit:\n\(formatted(violations))")
    }

    // MARK: - Application Layer (Use Cases — only Domain + Foundation)

    @Test("Application does not import Infrastructure")
    func applicationDoesNotImportInfrastructure() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterApplication",
            forbiddenImports: ["AIMeterInfrastructure"]
        )
        #expect(violations.isEmpty, "Application must not import Infrastructure:\n\(formatted(violations))")
    }

    @Test("Application does not import Presentation")
    func applicationDoesNotImportPresentation() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterApplication",
            forbiddenImports: ["AIMeterPresentation"]
        )
        #expect(violations.isEmpty, "Application must not import Presentation:\n\(formatted(violations))")
    }

    @Test("Application does not import SwiftUI")
    func applicationDoesNotImportSwiftUI() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterApplication",
            forbiddenImports: ["SwiftUI"]
        )
        #expect(violations.isEmpty, "Application must not import SwiftUI:\n\(formatted(violations))")
    }

    @Test("Application does not import AppKit")
    func applicationDoesNotImportAppKit() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterApplication",
            forbiddenImports: ["AppKit"]
        )
        #expect(violations.isEmpty, "Application must not import AppKit:\n\(formatted(violations))")
    }

    // MARK: - Infrastructure Layer (implementations — no Presentation)

    @Test("Infrastructure does not import Presentation")
    func infrastructureDoesNotImportPresentation() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterInfrastructure",
            forbiddenImports: ["AIMeterPresentation"]
        )
        #expect(violations.isEmpty, "Infrastructure must not import Presentation:\n\(formatted(violations))")
    }

    // MARK: - Presentation Layer (UI — no Infrastructure)

    @Test("Presentation does not import Infrastructure")
    func presentationDoesNotImportInfrastructure() throws {
        let violations = try findImportViolations(
            in: "Sources/AIMeterPresentation",
            forbiddenImports: ["AIMeterInfrastructure"]
        )
        #expect(violations.isEmpty, "Presentation must not import Infrastructure:\n\(formatted(violations))")
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

    private func formatted(_ violations: [String]) -> String {
        violations.map { "  - \($0)" }.joined(separator: "\n")
    }
}
