import SwiftUI

/// General settings tab - Launch at Login, Notifications
struct GeneralSettingsTab: View {
    var launchAtLogin: LaunchAtLoginService
    var notificationPreferences: NotificationPreferencesService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Launch at Login
            settingsRow(
                icon: "power",
                title: "Launch at Login",
                subtitle: "Start AIMeter when you log in",
                isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { _ in launchAtLogin.toggle() }
                )
            )

            Divider()

            // Notifications
            settingsRow(
                icon: "bell.badge",
                title: "Usage Alerts",
                subtitle: "Notify at 80% and 95% usage",
                isOn: Binding(
                    get: { notificationPreferences.isEnabled },
                    set: { notificationPreferences.isEnabled = $0 }
                )
            )

            Divider()

            Spacer()
        }
    }

    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: UIConstants.Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .toggleStyle(.switch)
        .padding(.horizontal, UIConstants.Spacing.xl)
        .padding(.vertical, UIConstants.Spacing.md)
    }
}
