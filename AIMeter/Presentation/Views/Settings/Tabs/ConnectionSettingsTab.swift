import SwiftUI

/// Connection settings tab - Claude connection status and sync
struct ConnectionSettingsTab: View {
    @Bindable var viewModel: SettingsViewModel

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
                loadingView

            case .success(let message):
                successView(message: message)

            case .error(let message):
                errorView(message: message)
            }

            Spacer()
        }
        .padding(UIConstants.Spacing.xl)
    }

    // MARK: - State Views

    private var checkingView: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Checking for Claude Code...")
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func claudeCodeFoundView(email: String?) -> some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            // Status
            statusCard(
                icon: "checkmark.circle.fill",
                iconColor: .green,
                title: "Claude Code detected!",
                subtitle: email,
                backgroundColor: .green.opacity(0.1)
            )

            // Sync button
            Button {
                Task { await viewModel.syncFromClaudeCode() }
            } label: {
                Label("Sync from Claude Code", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var claudeCodeNotFoundView: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            // Status
            statusCard(
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                title: "Claude Code not found",
                subtitle: "Please login to Claude Code first",
                backgroundColor: .orange.opacity(0.1)
            )

            // Instructions
            instructionsView

            // Retry button
            Button {
                Task { await viewModel.retry() }
            } label: {
                Label("Check Again", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
            Text("How to login:")
                .font(.subheadline.weight(.medium))

            VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                instructionStep(1, "Open Terminal")
                instructionStep(2, "Run: claude")
                instructionStep(3, "Login with Google/GitHub")
                instructionStep(4, "Click \"Check Again\"")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(UIConstants.Spacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium))
    }

    private func instructionStep(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: UIConstants.Spacing.sm) {
            Text("\(number).")
                .fontWeight(.medium)
                .frame(width: 16, alignment: .trailing)
            Text(text)
        }
    }

    private func existingKeyView(masked: String) -> some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            // Status
            statusCard(
                icon: "checkmark.circle.fill",
                iconColor: .green,
                title: "Connected",
                subtitle: masked,
                backgroundColor: .green.opacity(0.1)
            )

            // Re-sync button
            Button {
                Task { await viewModel.syncFromClaudeCode() }
            } label: {
                Label("Re-sync", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            // Disconnect button
            Button(role: .destructive) {
                Task { await viewModel.deleteKey() }
            } label: {
                Label("Disconnect", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private var loadingView: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Syncing...")
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func successView(message: String) -> some View {
        statusCard(
            icon: "checkmark.circle.fill",
            iconColor: .green,
            title: message,
            subtitle: nil,
            backgroundColor: .green.opacity(0.1)
        )
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            statusCard(
                icon: "xmark.circle.fill",
                iconColor: .red,
                title: "Error",
                subtitle: message,
                backgroundColor: .red.opacity(0.1)
            )

            Button {
                Task { await viewModel.retry() }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Helper Views

    private func statusCard(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String?,
        backgroundColor: Color
    ) -> some View {
        HStack(spacing: UIConstants.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(UIConstants.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium))
    }
}
