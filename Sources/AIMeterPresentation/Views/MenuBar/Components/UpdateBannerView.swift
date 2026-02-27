import SwiftUI

/// Banner shown in menu bar popover when a new update is available
struct UpdateBannerView: View {
    let version: String?
    let onInstall: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 1) {
                Text("Update available", tableName: "MenuBar", bundle: .main)
                    .font(.caption.bold())
                if let version {
                    Text("v\(version)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                onInstall()
            } label: {
                Text("Install", tableName: "MenuBar", bundle: .main)
                    .font(.caption.bold())
            }
            .glassButton()
        }
        .padding(.horizontal, UIConstants.SettingsCard.padding)
        .padding(.vertical, UIConstants.Spacing.sm)
        .glassCard()
        .padding(.horizontal, UIConstants.Spacing.md)
    }
}
