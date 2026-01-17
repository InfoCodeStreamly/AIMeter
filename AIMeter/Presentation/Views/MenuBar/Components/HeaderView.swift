import SwiftUI

/// Header view for menu bar popover
struct HeaderView: View {
    let lastUpdated: String
    let onRefresh: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                Text("Claude Usage")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("Updated \(lastUpdated)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: UIConstants.Spacing.sm) {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .help("Refresh")

                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
        }
        .padding(.horizontal, UIConstants.Spacing.md)
        .padding(.vertical, UIConstants.Spacing.sm)
    }
}

#Preview {
    HeaderView(
        lastUpdated: "2m ago",
        onRefresh: {},
        onSettings: {}
    )
    .frame(width: UIConstants.MenuBar.width)
    .background(.ultraThinMaterial)
}
