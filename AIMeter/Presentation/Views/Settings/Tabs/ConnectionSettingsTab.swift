import SwiftUI

/// Connection settings tab - Claude connection status and sync
struct ConnectionSettingsTab: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
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
            }
            .padding(UIConstants.Spacing.xl)
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
                    Text("Checking for Claude Code...")
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
                        .foregroundStyle(.green)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Claude Code detected!")
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
                style: .primary
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
                        .foregroundStyle(.orange)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Claude Code not found")
                            .font(.headline)

                        Text("Please login to Claude Code first")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }

            // Instructions
            SettingsCard(title: "How to login") {
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
                style: .primary
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
                        .foregroundStyle(.green)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connected")
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
                    style: .primary
                ) {
                    Task { await viewModel.syncFromClaudeCode() }
                }

                SettingsButton(
                    "Disconnect",
                    icon: "xmark.circle",
                    style: .destructive
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
                    Text("Syncing...")
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
                    .foregroundStyle(.green)
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
                        Text("Error")
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
                style: .primary
            ) {
                Task { await viewModel.retry() }
            }
        }
    }

    // MARK: - Helper Views

    private func instructionStep(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: UIConstants.Spacing.sm) {
            Text("\(number).")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 16, alignment: .trailing)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
