import Foundation
import Combine
import Sparkle

/// ViewModel для спостереження за станом оновлень Sparkle
/// Джерело: https://sparkle-project.org/documentation/programmatic-setup/
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}
