import SwiftUI
import AIMeterApplication
import AIMeterInfrastructure

/// Картка для групування налаштувань
struct SettingsCard<Content: View>: View {
    let title: LocalizedStringKey?
    let subtitle: LocalizedStringKey?
    let footer: LocalizedStringKey?
    let tableName: String?
    let content: Content

    init(
        title: LocalizedStringKey? = nil,
        subtitle: LocalizedStringKey? = nil,
        footer: LocalizedStringKey? = nil,
        tableName: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.footer = footer
        self.tableName = tableName
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            if title != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                    if let title {
                        Text(title, tableName: tableName, bundle: .main)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }
                    if let subtitle {
                        Text(subtitle, tableName: tableName, bundle: .main)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, UIConstants.SettingsCard.padding)
                .padding(.top, UIConstants.SettingsCard.padding)
                .padding(.bottom, UIConstants.Spacing.md)
            }

            // Content
            content
                .padding(.horizontal, UIConstants.SettingsCard.padding)
                .padding(.vertical, title == nil ? UIConstants.SettingsCard.padding : 0)
                .padding(.bottom, footer == nil ? UIConstants.SettingsCard.padding : UIConstants.Spacing.md)

            // Footer
            if let footer {
                Text(footer, tableName: tableName, bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, UIConstants.SettingsCard.padding)
                    .padding(.bottom, UIConstants.SettingsCard.padding)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                .strokeBorder(
                    Color.gray.opacity(UIConstants.SettingsCard.borderOpacity),
                    lineWidth: UIConstants.SettingsCard.borderWidth
                )
        )
    }
}

// MARK: - Convenience Initializers

extension SettingsCard {
    init(title: LocalizedStringKey, tableName: String? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, subtitle: nil, footer: nil, tableName: tableName, content: content)
    }

    init(@ViewBuilder content: () -> Content) {
        self.init(title: nil, subtitle: nil, footer: nil, tableName: nil, content: content)
    }
}

#Preview {
    VStack(spacing: 16) {
        SettingsCard(title: "General") {
            Text("Content here")
        }

        SettingsCard(title: "Advanced", footer: "This is a footer note") {
            Text("Content with footer")
        }

        SettingsCard {
            Text("Card without title")
        }
    }
    .padding()
    .frame(width: 400)
}
