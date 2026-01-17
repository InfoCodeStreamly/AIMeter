import SwiftUI
import AppKit

/// About settings tab - App info and links
struct AboutSettingsTab: View {
    var appInfo: AppInfoService

    var body: some View {
        VStack(spacing: UIConstants.Spacing.xl) {
            Spacer()

            // App icon and info
            VStack(spacing: UIConstants.Spacing.md) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(spacing: UIConstants.Spacing.xs) {
                    Text(appInfo.appName)
                        .font(.title2.weight(.semibold))

                    Text("Version \(appInfo.fullVersion)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("Made by \(appInfo.author)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Links
            VStack(spacing: UIConstants.Spacing.sm) {
                Button {
                    openGitHub()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                        Text("View Source on GitHub")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    openIssues()
                } label: {
                    HStack {
                        Image(systemName: "ladybug")
                        Text("Report a Bug")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.regular)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(UIConstants.Spacing.xl)
    }

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
