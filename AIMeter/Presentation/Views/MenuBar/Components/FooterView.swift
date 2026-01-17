import SwiftUI

/// Footer view for menu bar popover
struct FooterView: View {
    let onQuit: () -> Void

    var body: some View {
        HStack {
            Text("AIMeter")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Spacer()

            Button(action: onQuit) {
                Text("Quit")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
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
