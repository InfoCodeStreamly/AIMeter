import AIMeterInfrastructure
import AIMeterPresentation
import SwiftUI

/// Settings window content wrapper
struct SettingsWindowView: View {
    @State private var viewModel = DependencyContainer.shared.makeSettingsViewModel()
    @State private var voiceInputViewModel = DependencyContainer.shared.makeVoiceInputViewModel()
    let checkForUpdatesViewModel: CheckForUpdatesViewModel

    var body: some View {
        SettingsView(
            viewModel: viewModel,
            checkForUpdatesViewModel: checkForUpdatesViewModel,
            launchAtLogin: DependencyContainer.shared.launchAtLoginService,
            notificationPreferences: DependencyContainer.shared.notificationPreferencesService,
            appInfo: DependencyContainer.shared.appInfoService,
            voiceInputViewModel: voiceInputViewModel,
            voiceInputPreferences: DependencyContainer.shared.voiceInputPreferencesService
        )
        .windowLevel(UIConstants.WindowLevel.settings)
    }
}
