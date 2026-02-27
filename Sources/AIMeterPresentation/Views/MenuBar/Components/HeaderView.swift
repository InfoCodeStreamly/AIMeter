import AIMeterApplication
import SwiftUI

/// Header view for menu bar popover with Liquid Glass buttons
struct HeaderView: View {
    let lastUpdated: String
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onCopy: () -> Void
    let onSettings: () -> Void

    @State private var isCopied = false

    var body: some View {
        HStack(spacing: UIConstants.Spacing.md) {
            // App info
            HStack(spacing: UIConstants.Spacing.sm) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("AIMeter")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Updated \(lastUpdated)", tableName: "MenuBar", bundle: .main)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 2) {
                // Refresh button
                Button(action: onRefresh) {
                    ZStack {
                        if isRefreshing {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                }
                .glassButton()
                .disabled(isRefreshing)
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
                        .font(.caption2)
                        .foregroundStyle(isCopied ? AccessibleColors.success : .secondary)
                        .frame(width: 24, height: 24)
                }
                .glassButton()
                .help(
                    Text(
                        isCopied ? "Copied!" : "Copy to clipboard", tableName: "MenuBar",
                        bundle: .main))

                // Settings button
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
                .glassButton()
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
}
