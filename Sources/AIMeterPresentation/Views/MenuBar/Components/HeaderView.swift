import SwiftUI
import AIMeterApplication
import AIMeterInfrastructure

/// Header view for menu bar popover with refresh animation
struct HeaderView: View {
    let lastUpdated: String
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onCopy: () -> Void
    let onSettings: () -> Void

    @State private var isRefreshHovered = false
    @State private var isCopyHovered = false
    @State private var isCopied = false
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

                    Text("Updated \(lastUpdated)", tableName: "MenuBar", bundle: .main)
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
                .help(Text("Refresh", tableName: "MenuBar", bundle: .main))

                // Copy button
                Button {
                    onCopy()
                    withAnimation(.easeInOut(duration: UIConstants.Animation.fast)) {
                        isCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: UIConstants.Animation.fast)) {
                            isCopied = false
                        }
                    }
                } label: {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(isCopied ? .green : .secondary)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                                .fill(isCopyHovered ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: UIConstants.Animation.fast)) {
                        isCopyHovered = hovering
                    }
                }
                .help(Text(isCopied ? "Copied!" : "Copy to clipboard", tableName: "MenuBar", bundle: .main))

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
                .help(Text("Settings", tableName: "MenuBar", bundle: .main))
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
            onCopy: {},
            onSettings: {}
        )

        HeaderView(
            lastUpdated: "just now",
            isRefreshing: true,
            onRefresh: {},
            onCopy: {},
            onSettings: {}
        )
    }
    .frame(width: UIConstants.MenuBar.width)
    .background(.ultraThinMaterial)
}
