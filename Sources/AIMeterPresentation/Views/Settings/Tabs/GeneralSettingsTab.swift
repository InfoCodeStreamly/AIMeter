import SwiftUI
import AIMeterApplication
import AIMeterInfrastructure

/// General settings tab - Launch at Login, Notifications
struct GeneralSettingsTab: View {
    var launchAtLogin: LaunchAtLoginService
    var notificationPreferences: NotificationPreferencesService

    private let tableName = "SettingsGeneral"

    var body: some View {
        ScrollView {
            VStack(spacing: UIConstants.Spacing.lg) {
                // Startup
                SettingsCard(title: "Startup", tableName: tableName) {
                    SettingsToggle(
                        title: "Launch at Login",
                        description: "Start AIMeter when you log in",
                        icon: "power",
                        tableName: tableName,
                        isOn: Binding(
                            get: { launchAtLogin.isEnabled },
                            set: { _ in launchAtLogin.toggle() }
                        )
                    )
                }

                // Notifications
                SettingsCard(title: "Notifications", tableName: tableName) {
                    SettingsToggle(
                        title: "Usage Alerts",
                        description: "Notify at 80% and 95% usage",
                        icon: "bell.badge",
                        tableName: tableName,
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
