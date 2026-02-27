import Foundation

/// Protocol for inserting text into the active application via accessibility
@MainActor
public protocol TextInsertionServiceProtocol: Sendable {
    /// Checks if the app has accessibility permission
    func hasAccessibilityPermission() -> Bool

    /// Inserts text via clipboard + Cmd+V simulation
    /// - Parameter text: Text to insert
    func insertText(_ text: String) throws
}
