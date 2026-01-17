import SwiftUI

/// General settings tab - Launch at Login, Notifications
struct GeneralSettingsTab: View {
    var launchAtLogin: LaunchAtLoginService
    var notificationPreferences: NotificationPreferencesService

    var body: some View {
        ScrollView {
            VStack(spacing: UIConstants.Spacing.lg) {
                // Startup
                SettingsCard(title: String(localized: "Startup")) {
                    SettingsToggle(
                        title: String(localized: "Launch at Login"),
                        description: String(localized: "Start AIMeter when you log in"),
                        icon: "power",
                        isOn: Binding(
                            get: { launchAtLogin.isEnabled },
                            set: { _ in launchAtLogin.toggle() }
                        )
                    )
                }

                // Notifications
                SettingsCard(title: String(localized: "Notifications")) {
                    SettingsToggle(
                        title: String(localized: "Usage Alerts"),
                        description: String(localized: "Notify at 80% and 95% usage"),
                        icon: "bell.badge",
                        isOn: Binding(
                            get: { notificationPreferences.isEnabled },
                            set: { notificationPreferences.isEnabled = $0 }
                        )
                    )
                }

                Spacer()
            }
            .padding(UIConstants.Spacing.xl)
        }
    }
}
