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

    /// Theme service for appearance (SSOT)
    private let themeService = DependencyContainer.shared.themeService

    /// Sparkle updater controller (ініціалізується один раз)
    private let updaterController: SPUStandardUpdaterController

    /// Delegate for gentle update reminders (menu bar apps)
    private let gentleUpdateDelegate = GentleUpdateDelegate()

    /// Delegate for tracking update availability (indicator in menu bar)
    private let updateAvailabilityDelegate = UpdateAvailabilityDelegate()

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: updateAvailabilityDelegate,
            userDriverDelegate: gentleUpdateDelegate
        )
    }

    var body: some Scene {
        // Menu Bar
        MenuBarExtra {
            MenuBarView(
                viewModel: viewModel,
                updater: updaterController.updater,
                updateDelegate: updateAvailabilityDelegate
            )
            .environment(languageService)
            .environment(themeService)
            .environment(\.locale, languageService.currentLocale)
            .preferredColorScheme(themeService.selectedTheme.colorScheme)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)

        // Settings Window
        Window("AIMeter Settings", id: "settings") {
            SettingsWindowView(updater: updaterController.updater)
                .environment(languageService)
                .environment(themeService)
                .environment(\.locale, languageService.currentLocale)
                .preferredColorScheme(themeService.selectedTheme.colorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // Usage Detail Window
        Window("Usage Trend", id: "usage-detail") {
            UsageDetailView(viewModel: viewModel)
                .environment(languageService)
                .environment(themeService)
                .environment(\.locale, languageService.currentLocale)
                .preferredColorScheme(themeService.selectedTheme.colorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 520, height: 420)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    private var menuBarLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: viewModel.menuBarStatus.icon)
                .symbolRenderingMode(.palette)
                .foregroundStyle(viewModel.menuBarStatus.color)
                .overlay(alignment: .topTrailing) {
                    if updateAvailabilityDelegate.updateAvailable {
                        Circle()
                            .fill(.blue)
                            .frame(width: 6, height: 6)
                            .offset(x: 2, y: -2)
                    }
                }
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
