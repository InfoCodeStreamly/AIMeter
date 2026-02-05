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
        // Close settings window so Sparkle dialog appears in front
        NSApp.windows
            .filter { $0.title.contains("Settings") || $0.identifier?.rawValue == "settings" }
            .forEach { $0.close() }

        // Small delay to ensure window closes before Sparkle dialog appears
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            updater.checkForUpdates()
        }
    }
}
