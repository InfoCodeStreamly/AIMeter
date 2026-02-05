import SwiftUI
import Sparkle
import AppKit

/// ViewModel for "Check for Updates" button (Sparkle wrapper)
@MainActor
public final class CheckForUpdatesViewModel: ObservableObject {
    @Published public private(set) var canCheckForUpdates = false
    private let updater: SPUUpdater

    public init(updater: SPUUpdater) {
        self.updater = updater
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    public func checkForUpdates() {
        // Lower settings window level temporarily
        let settingsWindows = NSApp.windows.filter {
            $0.title.contains("Settings") || $0.identifier?.rawValue == "settings"
        }
        settingsWindows.forEach { $0.level = .normal }

        updater.checkForUpdates()

        // Bring Sparkle windows to front after a short delay
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            NSApp.windows
                .filter { $0.title.contains("AIMeter") || $0.className.contains("Sparkle") }
                .forEach { $0.orderFrontRegardless() }
        }
    }
}
