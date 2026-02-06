import SwiftUI
import AIMeterDomain
import AIMeterApplication
import AIMeterInfrastructure
import KeyboardShortcuts

/// General settings tab - Appearance, Launch at Login, Notifications, Keyboard Shortcuts
struct GeneralSettingsTab: View {
    var launchAtLogin: LaunchAtLoginService
    var notificationPreferences: NotificationPreferencesService
    @Environment(ThemeService.self) private var themeService

    private let tableName = "SettingsGeneral"

    var body: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            // Appearance
            SettingsCard(title: "Appearance", tableName: tableName) {
                    VStack(spacing: UIConstants.Spacing.sm) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            themeRow(theme)
                        }
                    }
                }

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
                    VStack(spacing: UIConstants.Spacing.md) {
                        SettingsToggle(
                            title: "Usage Alerts",
                            description: "Notify when usage reaches thresholds",
                            icon: "bell.badge",
                            tableName: tableName,
                            isOn: Binding(
                                get: { notificationPreferences.isEnabled },
                                set: { notificationPreferences.isEnabled = $0 }
                            )
                        )

                        if notificationPreferences.isEnabled {
                            Divider()

                            // Warning threshold slider
                            VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                                HStack {
                                    Label {
                                        Text("Warning Threshold", tableName: tableName, bundle: .main)
                                    } icon: {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundStyle(.orange)
                                    }
                                    Spacer()
                                    Text("\(notificationPreferences.warningThreshold)%")
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                Slider(
                                    value: Binding(
                                        get: { Double(notificationPreferences.warningThreshold) },
                                        set: { notificationPreferences.warningThreshold = Int($0) }
                                    ),
                                    in: 50...90,
                                    step: 5
                                )
                                .tint(.orange)
                            }

                            // Critical threshold slider
                            VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                                HStack {
                                    Label {
                                        Text("Critical Threshold", tableName: tableName, bundle: .main)
                                    } icon: {
                                        Image(systemName: "xmark.circle")
                                            .foregroundStyle(.red)
                                    }
                                    Spacer()
                                    Text("\(notificationPreferences.criticalThreshold)%")
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                Slider(
                                    value: Binding(
                                        get: { Double(notificationPreferences.criticalThreshold) },
                                        set: { notificationPreferences.criticalThreshold = Int($0) }
                                    ),
                                    in: 70...100,
                                    step: 5
                                )
                                .tint(.red)
                            }
                        }
                    }
                }

                // Keyboard Shortcut
                SettingsCard(title: "Keyboard Shortcut", tableName: tableName) {
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Toggle Menu", tableName: tableName, bundle: .main)
                                Text("Open or close the usage menu", tableName: tableName, bundle: .main)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "command")
                                .foregroundStyle(.blue)
                        }

                        Spacer()

                        KeyboardShortcuts.Recorder(for: .togglePopover)
                    }
                }

        }
        .padding(UIConstants.Spacing.xl)
    }

    // MARK: - Theme Row

    @MainActor
    private func themeRow(_ theme: AppTheme) -> some View {
        let isSelected = themeService.selectedTheme == theme

        return Button {
            withAnimation(.easeInOut(duration: UIConstants.Animation.fast)) {
                themeService.selectedTheme = theme
            }
        } label: {
            HStack(spacing: UIConstants.Spacing.md) {
                Image(systemName: theme.icon)
                    .font(.body)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 24)

                Text(theme.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, UIConstants.Spacing.sm)
            .padding(.horizontal, UIConstants.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
