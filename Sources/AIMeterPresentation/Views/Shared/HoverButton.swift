import SwiftUI
import AIMeterApplication
import AIMeterInfrastructure

/// Reusable button with hover effect and localization support
struct HoverButton: View {
    let icon: String
    let titleKey: LocalizedStringKey?
    let tableName: String?
    var isDestructive: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    init(
        icon: String,
        title: LocalizedStringKey? = nil,
        tableName: String? = nil,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.titleKey = title
        self.tableName = tableName
        self.isDestructive = isDestructive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: UIConstants.Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)

                if let titleKey = titleKey {
                    if let tableName = tableName {
                        Text(titleKey, tableName: tableName, bundle: .main)
                            .font(.caption)
                    } else {
                        Text(titleKey)
                            .font(.caption)
                    }
                }
            }
            .foregroundStyle(isDestructive ? .red : .primary)
            .padding(.horizontal, UIConstants.Spacing.sm)
            .padding(.vertical, UIConstants.Spacing.xs)
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
        HoverButton(icon: "gearshape", title: "Settings", tableName: "MenuBar") {}
        HoverButton(icon: "power", title: "Quit", tableName: "MenuBar", isDestructive: true) {}
        HoverButton(icon: "arrow.clockwise") {}
    }
    .padding()
}
