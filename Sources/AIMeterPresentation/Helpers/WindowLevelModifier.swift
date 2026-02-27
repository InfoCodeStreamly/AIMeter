import AppKit
import SwiftUI

/// Sets the NSWindow level for a SwiftUI view's hosting window.
/// Also prevents the window from hiding when the app deactivates (critical for menu bar apps).
struct WindowLevelModifier: ViewModifier {
    let level: NSWindow.Level

    func body(content: Content) -> some View {
        content.background(WindowLevelAccessor(level: level))
    }
}

/// Custom NSView that reliably captures the hosting NSWindow and applies level + hidesOnDeactivate.
private final class WindowLevelNSView: NSView {
    var level: NSWindow.Level
    nonisolated(unsafe) private var deactivateObserver: Any?

    init(level: NSWindow.Level) {
        self.level = level
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    deinit {
        if let deactivateObserver {
            NotificationCenter.default.removeObserver(deactivateObserver)
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyLevel()

        // Also re-apply after a short delay (SwiftUI may reset window properties)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.applyLevel()
        }

        // Observe app deactivation — re-apply level so window stays on top
        if window != nil, deactivateObserver == nil {
            deactivateObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.applyLevel()
                // Re-raise after brief delay (macOS may reorder windows on deactivation)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.window?.orderFrontRegardless()
                }
            }
        }
    }

    func applyLevel() {
        guard let window else { return }
        window.level = level
        window.hidesOnDeactivate = false
        window.collectionBehavior.insert(.fullScreenAuxiliary)
    }
}

private struct WindowLevelAccessor: NSViewRepresentable {
    let level: NSWindow.Level

    func makeNSView(context: Context) -> WindowLevelNSView {
        WindowLevelNSView(level: level)
    }

    func updateNSView(_ nsView: WindowLevelNSView, context: Context) {
        nsView.level = level
        nsView.applyLevel()
    }
}

public extension View {
    /// Sets the window level for the hosting NSWindow.
    /// The window stays visible above all other applications, even when AIMeter is not focused.
    func windowLevel(_ level: NSWindow.Level) -> some View {
        modifier(WindowLevelModifier(level: level))
    }
}
