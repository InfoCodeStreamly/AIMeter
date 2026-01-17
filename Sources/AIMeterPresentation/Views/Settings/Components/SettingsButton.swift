import SwiftUI
import AIMeterApplication
import AIMeterInfrastructure

/// Кнопка для налаштувань з hover-ефектом
struct SettingsButton: View {
    enum Style {
        case primary      // синій фон, білий текст
        case secondary    // бордер
        case destructive  // червоний
    }

    let title: LocalizedStringKey
    let icon: String?
    let style: Style
    let isLoading: Bool
    let tableName: String?
    let action: () -> Void

    @State private var isHovered = false

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
            .padding(.horizontal, UIConstants.Spacing.md)
            .padding(.vertical, UIConstants.Spacing.sm)
            .frame(maxWidth: style == .primary ? .infinity : nil)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .cornerRadius(UIConstants.CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                    .strokeBorder(borderColor, lineWidth: style == .secondary ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: UIConstants.Animation.fast)) {
                isHovered = hovering
            }
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isHovered ? .blue.opacity(0.85) : .blue
        case .secondary:
            return isHovered ? Color(nsColor: .controlBackgroundColor) : .clear
        case .destructive:
            return isHovered ? .red.opacity(0.85) : .red
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .primary
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary:
            return Color.gray.opacity(0.3)
        default:
            return .clear
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
