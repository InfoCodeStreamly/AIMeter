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
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

#Preview {
    FooterView(onQuit: {})
        .frame(width: 280)
}
