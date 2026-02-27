import Foundation

@MainActor
public protocol AccessibilityServiceProtocol: Sendable {
    func isAccessibilityGranted() -> Bool
    func requestAccessibilityPermission()
}
