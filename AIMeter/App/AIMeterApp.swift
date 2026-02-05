import SwiftUI
import Sparkle
import AIMeterDomain
import AIMeterApplication
import AIMeterInfrastructure
import AIMeterPresentation
import KeyboardShortcuts

@main
struct AIMeterApp: App {
    @State private var viewModel = DependencyContainer.shared.makeUsageViewModel()

    /// Language service for localization (SSOT)
    private let languageService = DependencyContainer.shared.languageService

    /// Keyboard shortcut service
    private let keyboardShortcutService = DependencyContainer.shared.keyboardShortcutService

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
            .environment(languageService)
            .environment(\.locale, languageService.currentLocale)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)

        // Settings Window
        Window("AIMeter Settings", id: "settings") {
            SettingsWindowView(updater: updaterController.updater)
                .environment(languageService)
                .environment(\.locale, languageService.currentLocale)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    private var menuBarLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: viewModel.menuBarStatus.icon)
                .symbolRenderingMode(.palette)
                .foregroundStyle(viewModel.menuBarStatus.color)
            Text(viewModel.menuBarText)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .monospacedDigit()
        }
        .task {
            await viewModel.startBackgroundRefresh()
        }
        .task {
            setupKeyboardShortcut()
        }
    }

    private func setupKeyboardShortcut() {
        keyboardShortcutService.onTogglePopover { [viewModel] in
            viewModel.copyToClipboard()
        }
    }
}
