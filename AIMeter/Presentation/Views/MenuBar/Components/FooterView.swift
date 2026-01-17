import SwiftUI
import AppKit

/// Footer view for menu bar popover with hover buttons
struct FooterView: View {
    let onQuit: () -> Void

    @State private var isLinkHovered = false

    var body: some View {
        HStack(spacing: UIConstants.Spacing.sm) {
            // App name with link
            HStack(spacing: 4) {
                Text("AIMeter by")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Button {
                    if let url = URL(string: "https://www.codestreamly.com/en/") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text("CodeStreamly")
                        .font(.caption2)
                        .foregroundStyle(isLinkHovered ? .blue : .secondary)
                        .underline(isLinkHovered)
                }
                .buttonStyle(.plain)
                .onHover { isLinkHovered = $0 }
            }

            Spacer()

            // Quit button
            HoverButton(
                icon: "power",
                title: "Quit",
                isDestructive: true,
                action: onQuit
            )
        }
        .padding(.horizontal, UIConstants.SettingsCard.padding)
        .padding(.vertical, UIConstants.Spacing.sm)
    }
}

#Preview {
    FooterView(onQuit: {})
        .frame(width: UIConstants.MenuBar.width)
        .background(.ultraThinMaterial)
}
