import AIMeterApplication
import SwiftUI

/// Organization settings tab - Admin API key management
struct OrganizationSettingsTab: View {
    @Bindable var viewModel: SettingsViewModel

    @State private var adminKeyInput: String = ""
    private let tableName = "SettingsOrganization"

    var body: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            // State-based content
            switch viewModel.adminKeyState {
            case .noKey:
                noKeyView

            case .hasKey(let masked):
                hasKeyView(masked: masked)

            case .testing:
                testingView

            case .valid:
                validView

            case .error(let message):
                errorView(message: message)
            }

            // Instructions
            instructionsSection
        }
        .padding(UIConstants.Spacing.xl)
    }

    // MARK: - State Views

    private var noKeyView: some View {
        SettingsCard(title: "Admin API Key", tableName: tableName) {
            VStack(spacing: UIConstants.Spacing.md) {
                SecureField(
                    text: $adminKeyInput,
                    prompt: Text("sk-ant-admin-...", tableName: tableName, bundle: .main)
                ) {
                    Text("API Key", tableName: tableName, bundle: .main)
                }
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

                SettingsButton(
                    "Connect",
                    icon: "link",
                    style: .primary,
                    tableName: tableName
                ) {
                    Task { await viewModel.saveAdminKey(adminKeyInput) }
                }
            }
        }
    }

    private func hasKeyView(masked: String) -> some View {
        SettingsCard {
            VStack(spacing: UIConstants.Spacing.md) {
                HStack(spacing: UIConstants.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AccessibleColors.success)
                        .font(.title3)

                    Text("Connected", tableName: tableName, bundle: .main)
                        .font(.headline)

                    Spacer()

                    Text(masked)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                SettingsButton(
                    "Disconnect",
                    icon: "xmark.circle",
                    style: .destructive,
                    tableName: tableName
                ) {
                    Task { await viewModel.deleteAdminKey() }
                }
            }
        }
    }

    private var testingView: some View {
        SettingsCard {
            HStack {
                Spacer()
                VStack(spacing: UIConstants.Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Validating key...", tableName: tableName, bundle: .main)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, UIConstants.Spacing.xl)
                Spacer()
            }
        }
    }

    private var validView: some View {
        SettingsCard {
            HStack(spacing: UIConstants.Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AccessibleColors.success)
                    .font(.title2)

                Text("Key validated!", tableName: tableName, bundle: .main)
                    .font(.headline)

                Spacer()
            }
        }
    }

    private func errorView(message: String) -> some View {
        SettingsCard {
            VStack(spacing: UIConstants.Spacing.md) {
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

                Divider()

                SettingsButton(
                    "Try Again",
                    icon: "arrow.clockwise",
                    style: .primary,
                    tableName: tableName
                ) {
                    adminKeyInput = ""
                    Task { await viewModel.checkAdminKey() }
                }
            }
        }
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        SettingsCard(title: "How to get Admin API Key", tableName: tableName) {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
                instructionStep(1, "Open console.anthropic.com")
                instructionStep(2, "Go to Settings → Admin Keys")
                instructionStep(3, "Create a new key")
                instructionStep(4, "Paste the key above")
            }
        }
    }

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
