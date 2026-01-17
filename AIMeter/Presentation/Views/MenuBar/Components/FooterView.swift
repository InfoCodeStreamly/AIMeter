import SwiftUI

/// Footer view for menu bar popover with hover buttons
struct FooterView: View {
    let onQuit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // App name
            Text("AIMeter")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)

            Spacer()

            // Quit button
            HoverButton(
                icon: "power",
                title: "Quit",
                isDestructive: true,
                action: onQuit
            )
        }
        .padding(.horizontal, UIConstants.Spacing.md)
        .padding(.vertical, UIConstants.Spacing.sm)
    }
}

#Preview {
    FooterView(onQuit: {})
        .frame(width: UIConstants.MenuBar.width)
        .background(.ultraThinMaterial)
}
