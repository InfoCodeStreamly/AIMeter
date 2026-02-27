import AIMeterApplication
import AppKit
import SwiftUI

/// About settings tab - App info, updates, and links
struct AboutSettingsTab: View {
    var checkForUpdatesViewModel: CheckForUpdatesViewModel
    var appInfo: any AppInfoServiceProtocol

    private let tableName = "SettingsAbout"
    private let updatesTableName = "SettingsUpdates"

    var body: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            // App info card
            SettingsCard {
                VStack(spacing: UIConstants.Spacing.md) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(spacing: UIConstants.Spacing.xs) {
                        Text(appInfo.appName)
                            .font(.title2.weight(.semibold))

                        Text("Version \(appInfo.fullVersion)", tableName: tableName, bundle: .main)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("Made by \(appInfo.author)", tableName: tableName, bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, UIConstants.Spacing.md)
            }

            // Updates
            if checkForUpdatesViewModel.canCheckForUpdates {
                SettingsButton(
                    "Check for Updates…",
                    icon: "arrow.clockwise",
                    style: .primary,
                    tableName: updatesTableName
                ) {
                    checkForUpdatesViewModel.checkForUpdates()
                }
            } else {
                SettingsButton(
                    "Checking…",
                    style: .primary,
                    isLoading: true,
                    tableName: updatesTableName
                ) {
                    checkForUpdatesViewModel.checkForUpdates()
                }
            }

            Text("Updates are checked automatically", tableName: updatesTableName, bundle: .main)
                .font(.caption)
                .foregroundStyle(.tertiary)

            // Links card
            SettingsCard(title: "Links", tableName: tableName) {
                VStack(spacing: UIConstants.Spacing.sm) {
                    linkButton(
                        icon: "chevron.left.forwardslash.chevron.right",
                        title: "View Source on GitHub",
                        action: openGitHub
                    )

                    linkButton(
                        icon: "ladybug",
                        title: "Report a Bug",
                        action: openIssues
                    )
                }
            }
        }
        .padding(UIConstants.Spacing.xl)
    }

    // MARK: - Helper Views

    private func linkButton(icon: String, title: LocalizedStringKey, action: @escaping () -> Void)
        -> some View
    {
        Button(action: action) {
            HStack(spacing: UIConstants.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .frame(width: 20)

                Text(title, tableName: tableName, bundle: .main)
                    .font(.body)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, UIConstants.Spacing.xs)
        }
        .glassButton()
        .foregroundStyle(.primary)
    }

    // MARK: - Actions

    private func openGitHub() {
        if let url = URL(string: "\(AppConstants.GitHub.repoURL)/releases") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openIssues() {
        if let url = URL(string: "\(AppConstants.GitHub.repoURL)/issues") {
            NSWorkspace.shared.open(url)
        }
    }
}
