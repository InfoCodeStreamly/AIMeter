import SwiftUI
import Sparkle

/// Settings window content wrapper
struct SettingsWindowView: View {
    @State private var viewModel = DependencyContainer.shared.makeSettingsViewModel()
    let updater: SPUUpdater

    var body: some View {
        SettingsView(
            viewModel: viewModel,
            updater: updater,
            launchAtLogin: DependencyContainer.shared.launchAtLoginService,
            notificationPreferences: DependencyContainer.shared.notificationPreferencesService,
            appInfo: DependencyContainer.shared.appInfoService
        )
    }
}
