import SwiftUI
import AIMeterApplication
import AIMeterInfrastructure
import AppKit

/// About settings tab - App info and links
struct AboutSettingsTab: View {
    var appInfo: AppInfoService

    private let tableName = "SettingsAbout"

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

    private func linkButton(icon: String, title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
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
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    // MARK: - Actions

    private func openGitHub() {
        if let url = URL(string: APIConstants.GitHub.repoURL) {
            NSWorkspace.shared.open(url)
        }
    }

    private func openIssues() {
        if let url = URL(string: "\(APIConstants.GitHub.repoURL)/issues") {
            NSWorkspace.shared.open(url)
        }
    }
}
