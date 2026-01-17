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
        HStack(spacing: 12) {
            // App info
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AIMeter")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Updated \(lastUpdated)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 4) {
                // Refresh button
                Button(action: onRefresh) {
                    ZStack {
                        if isRefreshing {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                            .fill(isRefreshHovered ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .disabled(isRefreshing)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: UIConstants.Animation.fast)) {
                        isRefreshHovered = hovering
                    }
                }
                .help("Refresh")

                // Settings button
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                                .fill(isSettingsHovered ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: UIConstants.Animation.fast)) {
                        isSettingsHovered = hovering
                    }
                }
                .help("Settings")
            }
        }
        .padding(.horizontal, UIConstants.Spacing.md)
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
