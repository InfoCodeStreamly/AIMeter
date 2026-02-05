import Foundation
import KeyboardShortcuts

/// Extension to define global keyboard shortcuts
public extension KeyboardShortcuts.Name {
    /// Shortcut to toggle the menu bar popover
    static let togglePopover = Self("togglePopover")
}

/// Service for managing global keyboard shortcuts
@MainActor
public final class KeyboardShortcutService {
    public init() {
        // Set default shortcut if not already set
        if KeyboardShortcuts.getShortcut(for: .togglePopover) == nil {
            KeyboardShortcuts.setShortcut(.init(.u, modifiers: [.command, .shift]), for: .togglePopover)
        }
    }

    /// Registers handler for toggle popover shortcut
    public func onTogglePopover(_ handler: @escaping () -> Void) {
        KeyboardShortcuts.onKeyUp(for: .togglePopover) {
            handler()
        }
    }
}
