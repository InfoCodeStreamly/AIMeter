import AIMeterApplication
import SwiftUI

/// Organization settings tab - Admin API key management
struct OrganizationSettingsTab: View {
    @Bindable var viewModel: SettingsViewModel

    @State private var adminKeyInput: String = ""
    @State private var apiKeyInput: String = ""
    private let tableName = "SettingsOrganization"

    var body: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            // State-based content
            switch viewModel.adminKeyState {
            case .noKey, .error:
                inputView

            case .hasKey(let masked):
                hasKeyView(masked: masked)

            case .testing:
                testingView

            case .valid:
                validView
            }

            // API Key section
            apiKeySection

            // Instructions
            instructionsSection
        }
        .padding(UIConstants.Spacing.xl)
    }

    // MARK: - State Views

    private var inputView: some View {
        SettingsCard(title: "Admin API Key", tableName: tableName) {
            VStack(spacing: UIConstants.Spacing.md) {
                // Error message (inline)
                if case .error(let message) = viewModel.adminKeyState {
                    HStack(spacing: UIConstants.Spacing.sm) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)

                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)

                        Spacer()
                    }
                }

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

    // MARK: - API Key Section

    private var apiKeySection: some View {
        Group {
            switch viewModel.apiKeyState {
            case .noKey, .error:
                apiKeyInputView

            case .hasKey(let masked):
                apiKeyHasKeyView(masked: masked)

            case .testing:
                SettingsCard {
                    HStack {
                        Spacer()
                        VStack(spacing: UIConstants.Spacing.md) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Validating API key...", tableName: tableName, bundle: .main)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, UIConstants.Spacing.xl)
                        Spacer()
                    }
                }
            }
        }
    }

    private var apiKeyInputView: some View {
        SettingsCard(title: "API Key", tableName: tableName) {
            VStack(spacing: UIConstants.Spacing.md) {
                if case .error(let message) = viewModel.apiKeyState {
                    HStack(spacing: UIConstants.Spacing.sm) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)

                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)

                        Spacer()
                    }
                }

                SecureField(
                    text: $apiKeyInput,
                    prompt: Text("sk-ant-api03-...", tableName: tableName, bundle: .main)
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
                    Task { await viewModel.saveAPIKey(apiKeyInput) }
                }
            }
        }
    }

    private func apiKeyHasKeyView(masked: String) -> some View {
        SettingsCard {
            VStack(spacing: UIConstants.Spacing.md) {
                HStack(spacing: UIConstants.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AccessibleColors.success)
                        .font(.title3)

                    Text("API Key Connected", tableName: tableName, bundle: .main)
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
                    Task { await viewModel.deleteAPIKey() }
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
