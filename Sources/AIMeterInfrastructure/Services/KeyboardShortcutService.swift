import Foundation
import KeyboardShortcuts

/// Service for managing global keyboard shortcuts
@MainActor
public final class KeyboardShortcutService {
    private static let togglePopoverName = KeyboardShortcuts.Name("togglePopover")

    public init() {
        // Set default shortcut if not already set
        if KeyboardShortcuts.getShortcut(for: Self.togglePopoverName) == nil {
            KeyboardShortcuts.setShortcut(.init(.u, modifiers: [.command, .shift]), for: Self.togglePopoverName)
        }
    }

    /// Registers handler for toggle popover shortcut
    public func onTogglePopover(_ handler: @escaping () -> Void) {
        KeyboardShortcuts.onKeyUp(for: Self.togglePopoverName) {
            handler()
        }
    }
}
