import SwiftUI
import Sparkle

@main
struct AIMeterApp: App {
    @State private var viewModel = DependencyContainer.shared.makeUsageViewModel()

    /// Sparkle updater controller (ініціалізується один раз)
    private let updaterController: SPUStandardUpdaterController

    /// Delegate for gentle update reminders (menu bar apps)
    private let gentleUpdateDelegate = GentleUpdateDelegate()

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: gentleUpdateDelegate
        )
    }

    var body: some Scene {
        // Menu Bar
        MenuBarExtra {
            MenuBarView(
                viewModel: viewModel,
                updater: updaterController.updater
            )
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)

        // Settings Window
        Window("AIMeter Settings", id: "settings") {
            SettingsWindowView(updater: updaterController.updater)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    private var menuBarLabel: some View {
        Text(viewModel.menuBarText)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .monospacedDigit()
    }
}
