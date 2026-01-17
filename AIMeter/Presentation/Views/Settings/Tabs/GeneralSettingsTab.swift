import SwiftUI

/// General settings tab - Launch at Login, Notifications
struct GeneralSettingsTab: View {
    var launchAtLogin: LaunchAtLoginService
    var notificationPreferences: NotificationPreferencesService

    var body: some View {
        ScrollView {
            VStack(spacing: UIConstants.Spacing.lg) {
                // Startup
                SettingsCard(title: "Startup") {
                    SettingsToggle(
                        title: "Launch at Login",
                        description: "Start AIMeter when you log in",
                        icon: "power",
                        isOn: Binding(
                            get: { launchAtLogin.isEnabled },
                            set: { _ in launchAtLogin.toggle() }
                        )
                    )
                }

                // Notifications
                SettingsCard(title: "Notifications") {
                    SettingsToggle(
                        title: "Usage Alerts",
                        description: "Notify at 80% and 95% usage",
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
