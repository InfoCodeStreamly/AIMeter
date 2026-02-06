import AIMeterApplication
import AIMeterInfrastructure
import SwiftUI

/// Reusable button with Liquid Glass effect and localization support
struct HoverButton: View {
    let icon: String
    let titleKey: LocalizedStringKey?
    let tableName: String?
    var isDestructive: Bool = false
    let action: () -> Void

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
        }
        .glassButton()
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
