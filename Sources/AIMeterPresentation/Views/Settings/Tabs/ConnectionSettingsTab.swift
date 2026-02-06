import AIMeterApplication
import AIMeterInfrastructure
import SwiftUI

/// Connection settings tab - Claude connection status, sync, and notifications
struct ConnectionSettingsTab: View {
    @Bindable var viewModel: SettingsViewModel
    var notificationPreferences: NotificationPreferencesService

    private let tableName = "SettingsConnection"
    private let generalTableName = "SettingsGeneral"

    var body: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            // State-based content
            switch viewModel.state {
            case .checking:
                checkingView

            case .claudeCodeFound(let email):
                claudeCodeFoundView(email: email)

            case .claudeCodeNotFound:
                claudeCodeNotFoundView

            case .hasKey(let masked):
                existingKeyView(masked: masked)

            case .syncing:
                syncingView

            case .success(let message):
                successView(message: message)

            case .error(let message):
                errorView(message: message)
            }

            // Notifications
            notificationsSection
        }
        .padding(UIConstants.Spacing.xl)
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        SettingsCard(title: "Notifications", tableName: generalTableName) {
            VStack(spacing: UIConstants.Spacing.md) {
                SettingsToggle(
                    title: "Usage Alerts",
                    description: "Notify when usage reaches thresholds",
                    icon: "bell.badge",
                    tableName: generalTableName,
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
                                Text(
                                    "Warning Threshold", tableName: generalTableName, bundle: .main)
                            } icon: {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(AccessibleColors.moderate)
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
                        .tint(AccessibleColors.moderate)
                    }

                    // Critical threshold slider
                    VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                        HStack {
                            Label {
                                Text(
                                    "Critical Threshold", tableName: generalTableName, bundle: .main
                                )
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
    }

    // MARK: - State Views

    private var checkingView: some View {
        SettingsCard {
            HStack {
                Spacer()
                VStack(spacing: UIConstants.Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Checking for Claude Code...", tableName: tableName, bundle: .main)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, UIConstants.Spacing.xl)
                Spacer()
            }
        }
    }

    private func claudeCodeFoundView(email: String?) -> some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            // Status card
            SettingsCard {
                HStack(spacing: UIConstants.Spacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AccessibleColors.success)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Claude Code detected!", tableName: tableName, bundle: .main)
                            .font(.headline)

                        if let email {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
            }

            // Sync button
            SettingsButton(
                "Sync from Claude Code",
                icon: "arrow.triangle.2.circlepath",
                style: .primary,
                tableName: tableName
            ) {
                Task { await viewModel.syncFromClaudeCode() }
            }
        }
    }

    private var claudeCodeNotFoundView: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            // Status card
            SettingsCard {
                HStack(spacing: UIConstants.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AccessibleColors.moderate)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Claude Code not found", tableName: tableName, bundle: .main)
                            .font(.headline)

                        Text(
                            "Please login to Claude Code first", tableName: tableName, bundle: .main
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }

            // Instructions
            SettingsCard(title: "How to login", tableName: tableName) {
                VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
                    instructionStep(1, "Open Terminal")
                    instructionStep(2, "Run: claude")
                    instructionStep(3, "Login with Google/GitHub")
                    instructionStep(4, "Click \"Check Again\"")
                }
            }

            // Retry button
            SettingsButton(
                "Check Again",
                icon: "arrow.clockwise",
                style: .primary,
                tableName: tableName
            ) {
                Task { await viewModel.retry() }
            }
        }
    }

    private func existingKeyView(masked: String) -> some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            // Status card
            SettingsCard {
                HStack(spacing: UIConstants.Spacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AccessibleColors.success)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connected", tableName: tableName, bundle: .main)
                            .font(.headline)

                        Text(masked)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }

            // Actions
            VStack(spacing: UIConstants.Spacing.sm) {
                SettingsButton(
                    "Re-sync",
                    icon: "arrow.triangle.2.circlepath",
                    style: .primary,
                    tableName: tableName
                ) {
                    Task { await viewModel.syncFromClaudeCode() }
                }

                SettingsButton(
                    "Disconnect",
                    icon: "xmark.circle",
                    style: .destructive,
                    tableName: tableName
                ) {
                    Task { await viewModel.deleteKey() }
                }
            }
        }
    }

    private var syncingView: some View {
        SettingsCard {
            HStack {
                Spacer()
                VStack(spacing: UIConstants.Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Syncing...", tableName: tableName, bundle: .main)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, UIConstants.Spacing.xl)
                Spacer()
            }
        }
    }

    private func successView(message: String) -> some View {
        SettingsCard {
            HStack(spacing: UIConstants.Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AccessibleColors.success)
                    .font(.title2)

                Text(message)
                    .font(.headline)

                Spacer()
            }
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            SettingsCard {
                HStack(spacing: UIConstants.Spacing.md) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Error", tableName: tableName, bundle: .main)
                            .font(.headline)

                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }

            SettingsButton(
                "Try Again",
                icon: "arrow.clockwise",
                style: .primary,
                tableName: tableName
            ) {
                Task { await viewModel.retry() }
            }
        }
    }

    // MARK: - Helper Views

    private func instructionStep(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: UIConstants.Spacing.sm) {
            Text("\(number).")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 16, alignment: .trailing)

            Text(text, tableName: tableName, bundle: .main)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
