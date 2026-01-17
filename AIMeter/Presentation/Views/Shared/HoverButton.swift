import SwiftUI

/// Reusable button with hover effect
struct HoverButton: View {
    let icon: String
    let title: String?
    var isDestructive: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    init(icon: String, title: String? = nil, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isDestructive = isDestructive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))

                if let title = title {
                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .foregroundStyle(isDestructive ? .red : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                    .fill(
                        isHovered
                            ? (isDestructive ? Color.red.opacity(0.1) : Color.accentColor.opacity(0.1))
                            : Color.clear
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: UIConstants.Animation.fast)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        HoverButton(icon: "gearshape", title: "Settings") {}
        HoverButton(icon: "power", title: "Quit", isDestructive: true) {}
        HoverButton(icon: "arrow.clockwise") {}
    }
    .padding()
}
