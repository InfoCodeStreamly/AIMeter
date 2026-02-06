import AIMeterApplication
import AIMeterInfrastructure
import SwiftUI

/// Кнопка для налаштувань з Liquid Glass стилем
struct SettingsButton: View {
    enum Style {
        case primary  // синій glass
        case secondary  // прозорий glass
        case destructive  // червоний glass
    }

    let title: LocalizedStringKey
    let icon: String?
    let style: Style
    let isLoading: Bool
    let tableName: String?
    let action: () -> Void

    init(
        _ title: LocalizedStringKey,
        icon: String? = nil,
        style: Style = .secondary,
        isLoading: Bool = false,
        tableName: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.tableName = tableName
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(title, tableName: tableName, bundle: .main)
                    .font(.body)
            }
            .frame(maxWidth: style == .primary ? .infinity : nil)
        }
        .glassButton()
        .tint(tintColor)
        .disabled(isLoading)
    }

    private var tintColor: Color? {
        switch style {
        case .primary: return .blue
        case .secondary: return nil
        case .destructive: return .red
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SettingsButton("Primary Action", icon: "arrow.clockwise", style: .primary) {}

        SettingsButton("Secondary", icon: "gear", style: .secondary) {}

        SettingsButton("Delete", icon: "trash", style: .destructive) {}

        SettingsButton("Loading...", style: .primary, isLoading: true) {}
    }
    .padding()
    .frame(width: 300)
}
