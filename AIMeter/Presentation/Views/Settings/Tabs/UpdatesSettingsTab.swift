import SwiftUI
import Sparkle

/// Updates settings tab - Check for updates, auto-update settings
struct UpdatesSettingsTab: View {
    let updater: SPUUpdater
    @ObservedObject var checkForUpdatesViewModel: CheckForUpdatesViewModel
    var appInfo: AppInfoService

    var body: some View {
        ScrollView {
            VStack(spacing: UIConstants.Spacing.lg) {
                Spacer()
                    .frame(height: UIConstants.Spacing.xl)

                // Current version card
                SettingsCard {
                    VStack(spacing: UIConstants.Spacing.md) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)

                        Text("AIMeter is up to date")
                            .font(.headline)

                        Text("Version \(appInfo.fullVersion)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, UIConstants.Spacing.md)
                }

                // Check for updates button
                SettingsButton(
                    checkForUpdatesViewModel.canCheckForUpdates
                        ? "Check for Updates…"
                        : "Checking…",
                    icon: checkForUpdatesViewModel.canCheckForUpdates
                        ? "arrow.clockwise"
                        : nil,
                    style: .primary,
                    isLoading: !checkForUpdatesViewModel.canCheckForUpdates
                ) {
                    updater.checkForUpdates()
                }

                Text("Updates are checked automatically")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()
            }
            .padding(UIConstants.Spacing.xl)
        }
    }
}
