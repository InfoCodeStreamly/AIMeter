import AppKit
import ApplicationServices
import AIMeterDomain
import AIMeterApplication

/// Service for inserting text into the active application via clipboard + Cmd+V
@MainActor
public final class TextInsertionService: TextInsertionServiceProtocol {
    public init() {}

    public func hasAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    public func insertText(_ text: String) throws {
        guard AXIsProcessTrusted() else {
            // Prompt user to grant accessibility permission
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            throw TranscriptionError.accessibilityDenied
        }

        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Cmd+V
        let source = CGEventSource(stateID: CGEventSourceStateID(rawValue: 1)!) // hidEventState
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // 'v'
        keyDown?.flags = CGEventFlags.maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = CGEventFlags.maskCommand
        keyDown?.post(tap: CGEventTapLocation.cghidEventTap)
        keyUp?.post(tap: CGEventTapLocation.cghidEventTap)

        // Restore clipboard after a delay
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            pasteboard.clearContents()
            if let prev = previousContents {
                pasteboard.setString(prev, forType: .string)
            }
        }
    }
}
