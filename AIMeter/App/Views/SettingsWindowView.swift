import AIMeterInfrastructure
import AIMeterPresentation
import SwiftUI

/// Settings window content wrapper
struct SettingsWindowView: View {
    @State private var viewModel = DependencyContainer.shared.makeSettingsViewModel()
    @State private var voiceInputViewModel = DependencyContainer.shared.makeVoiceInputViewModel()
    let checkForUpdatesViewModel: CheckForUpdatesViewModel
    var orgUsageViewModel: OrgUsageViewModel?
    var usageViewModel: UsageViewModel?

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
        .onAppear {
            viewModel.onSaveSuccess = { [orgUsageViewModel, usageViewModel] in
                Task { @MainActor in
                    await orgUsageViewModel?.recheckAndRestart()
                    usageViewModel?.reloadAfterSync()
                }
            }
            viewModel.onAdminKeyChanged = { [orgUsageViewModel, usageViewModel] in
                Task { @MainActor in
                    await orgUsageViewModel?.recheckAndRestart()
                    usageViewModel?.recheckSetup()
                }
            }
            viewModel.onAPIKeyChanged = { [orgUsageViewModel, usageViewModel] in
                Task { @MainActor in
                    await orgUsageViewModel?.recheckAndRestart()
                    usageViewModel?.recheckSetup()
                }
            }
        }
    }
}
