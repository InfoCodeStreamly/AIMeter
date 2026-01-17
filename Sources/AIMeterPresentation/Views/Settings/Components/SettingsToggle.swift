import SwiftUI
import AIMeterApplication
import AIMeterInfrastructure

/// Toggle з іконкою та описом
struct SettingsToggle: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey?
    let icon: String?
    let tableName: String?
    @Binding var isOn: Bool

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey? = nil,
        icon: String? = nil,
        tableName: String? = nil,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.tableName = tableName
        self._isOn = isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: UIConstants.Spacing.md) {
                if let icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title, tableName: tableName, bundle: .main)
                        .font(.body)

                    if let description {
                        Text(description, tableName: tableName, bundle: .main)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
        }
        .toggleStyle(.switch)
    }
}

#Preview {
    VStack(spacing: 16) {
        SettingsToggle(
            title: "Launch at Login",
            description: "Start app when you log in",
            icon: "power",
            isOn: .constant(true)
        )

        SettingsToggle(
            title: "Notifications",
            description: "Receive usage alerts",
            icon: "bell.badge",
            isOn: .constant(false)
        )

        SettingsToggle(
            title: "Simple toggle",
            isOn: .constant(true)
        )
    }
    .padding()
    .frame(width: 350)
}
