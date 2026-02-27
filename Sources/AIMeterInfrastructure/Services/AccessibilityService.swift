import AIMeterApplication
import ApplicationServices

@MainActor
public final class AccessibilityService: AccessibilityServiceProtocol {
    public init() {}

    public func isAccessibilityGranted() -> Bool {
        AXIsProcessTrusted()
    }

    public func requestAccessibilityPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
