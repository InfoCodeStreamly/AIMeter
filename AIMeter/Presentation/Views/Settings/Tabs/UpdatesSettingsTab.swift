import SwiftUI
import Sparkle

/// Updates settings tab - Check for updates, auto-update settings
struct UpdatesSettingsTab: View {
    let updater: SPUUpdater
    @ObservedObject var checkForUpdatesViewModel: CheckForUpdatesViewModel
    var appInfo: AppInfoService

    var body: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            Spacer()

            // Current version info
            VStack(spacing: UIConstants.Spacing.sm) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("AIMeter is up to date")
                    .font(.headline)

                Text("Version \(appInfo.fullVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Check for updates button
            VStack(spacing: UIConstants.Spacing.md) {
                Button {
                    updater.checkForUpdates()
                } label: {
                    Text("Check for Updates…")
                        .frame(width: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!checkForUpdatesViewModel.canCheckForUpdates)

                Text("Updates are checked automatically")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(UIConstants.Spacing.xl)
    }
}
