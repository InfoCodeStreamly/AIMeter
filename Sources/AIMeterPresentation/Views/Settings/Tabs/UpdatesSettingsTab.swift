import SwiftUI
import AIMeterApplication
import AIMeterInfrastructure
import Sparkle

/// Updates settings tab - Check for updates, auto-update settings
struct UpdatesSettingsTab: View {
    let updater: SPUUpdater
    @ObservedObject var checkForUpdatesViewModel: CheckForUpdatesViewModel
    var appInfo: AppInfoService

    private let tableName = "SettingsUpdates"

    var body: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            // Current version card
                SettingsCard {
                    VStack(spacing: UIConstants.Spacing.md) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)

                        Text("AIMeter is up to date", tableName: tableName, bundle: .main)
                            .font(.headline)

                        Text("Version \(appInfo.fullVersion)", tableName: tableName, bundle: .main)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, UIConstants.Spacing.md)
                }

                // Check for updates button
                if checkForUpdatesViewModel.canCheckForUpdates {
                    SettingsButton(
                        "Check for Updates…",
                        icon: "arrow.clockwise",
                        style: .primary,
                        tableName: tableName
                    ) {
                        updater.checkForUpdates()
                    }
                } else {
                    SettingsButton(
                        "Checking…",
                        style: .primary,
                        isLoading: true,
                        tableName: tableName
                    ) {
                        updater.checkForUpdates()
                    }
                }

            Text("Updates are checked automatically", tableName: tableName, bundle: .main)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(UIConstants.Spacing.xl)
    }
}
