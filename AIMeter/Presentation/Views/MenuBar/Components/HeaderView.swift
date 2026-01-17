import SwiftUI

/// Header view for menu bar popover with refresh animation
struct HeaderView: View {
    let lastUpdated: String
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onSettings: () -> Void

    @State private var isRefreshHovered = false
    @State private var isSettingsHovered = false

    var body: some View {
        HStack(spacing: UIConstants.Spacing.md) {
            // App info
            HStack(spacing: UIConstants.Spacing.sm) {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AIMeter")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Updated \(lastUpdated)", tableName: "Localizable")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: UIConstants.Spacing.xs) {
                // Refresh button
                Button(action: onRefresh) {
                    ZStack {
                        if isRefreshing {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                            .fill(isRefreshHovered ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                .disabled(isRefreshing)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: UIConstants.Animation.fast)) {
                        isRefreshHovered = hovering
                    }
                }
                .help(String(localized: "Refresh"))

                // Settings button
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                                .fill(isSettingsHovered ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: UIConstants.Animation.fast)) {
                        isSettingsHovered = hovering
                    }
                }
                .help(String(localized: "Settings"))
            }
        }
        .padding(.horizontal, UIConstants.SettingsCard.padding)
        .padding(.vertical, UIConstants.Spacing.md)
    }
}

#Preview {
    VStack(spacing: 20) {
        HeaderView(
            lastUpdated: "2m ago",
            isRefreshing: false,
            onRefresh: {},
            onSettings: {}
        )

        HeaderView(
            lastUpdated: "just now",
            isRefreshing: true,
            onRefresh: {},
            onSettings: {}
        )
    }
    .frame(width: UIConstants.MenuBar.width)
    .background(.ultraThinMaterial)
}
