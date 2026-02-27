import AIMeterApplication
import AIMeterDomain
import AIMeterInfrastructure
import AIMeterPresentation
import KeyboardShortcuts
import Sparkle
import SwiftUI

@main
struct AIMeterApp: App {
    @State private var viewModel = DependencyContainer.shared.makeUsageViewModel()
    @State private var voiceInputViewModel = DependencyContainer.shared.makeVoiceInputViewModel()

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

    /// ViewModel for "Check for Updates" button
    private let checkForUpdatesViewModel: CheckForUpdatesViewModel

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: updateAvailabilityDelegate,
            userDriverDelegate: gentleUpdateDelegate
        )
        checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updaterController.updater)
    }

    var body: some Scene {
        // Menu Bar
        MenuBarExtra {
            MenuBarView(
                viewModel: viewModel,
                updater: updaterController.updater
            )
            .environment(updateAvailabilityDelegate)
            .environment(\.languageService, languageService)
            .environment(\.themeService, themeService)
            .environment(\.locale, languageService.currentLocale)
            .preferredColorScheme(themeService.selectedTheme.colorScheme)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)

        // Settings Window
        Window("AIMeter Settings", id: UIConstants.WindowID.settings) {
            SettingsWindowView(
                checkForUpdatesViewModel: checkForUpdatesViewModel
            )
            .environment(\.languageService, languageService)
            .environment(\.themeService, themeService)
            .environment(\.locale, languageService.currentLocale)
            .preferredColorScheme(themeService.selectedTheme.colorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // Usage Detail Window
        Window("Usage Trend", id: UIConstants.WindowID.usageDetail) {
            UsageDetailView(viewModel: viewModel)
                .windowLevel(.init(NSWindow.Level.floating.rawValue))
                .environment(\.languageService, languageService)
                .environment(\.themeService, themeService)
                .environment(\.notificationPreferences, DependencyContainer.shared.notificationPreferencesService)
                .environment(\.locale, languageService.currentLocale)
                .preferredColorScheme(themeService.selectedTheme.colorScheme)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(
            width: UIConstants.UsageDetail.windowWidth, height: UIConstants.UsageDetail.windowHeight
        )
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

        // Push-to-talk: hold to record, release to stop & insert
        KeyboardShortcuts.onKeyDown(for: .voiceInput) { [voiceInputViewModel] in
            voiceInputViewModel.startRecordingIfReady()
        }
        KeyboardShortcuts.onKeyUp(for: .voiceInput) { [voiceInputViewModel] in
            voiceInputViewModel.stopIfRecording()
        }
    }
}
