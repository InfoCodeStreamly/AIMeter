import SwiftUI

/// Settings window view
struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: UIConstants.Settings.windowWidth, height: UIConstants.Settings.windowHeight)
        .background(.ultraThinMaterial)
        .task {
            await viewModel.onAppear()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .foregroundStyle(.secondary)
            Text("Settings")
                .font(.headline)
            Spacer()
        }
        .padding(UIConstants.Spacing.lg)
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.xl) {
                connectionSection
            }
            .padding(UIConstants.Spacing.xl)
        }
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            Label("Claude Connection", systemImage: "link")
                .font(.subheadline.weight(.semibold))

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

            case .syncing, .validating:
                loadingView

            case .success(let message):
                successView(message: message)

            case .error(let message):
                errorView(message: message)

            case .manualEntry:
                manualEntryView
            }
        }
    }

    // MARK: - State Views

    private var checkingView: some View {
        HStack(spacing: UIConstants.Spacing.md) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Checking for Claude Code...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(UIConstants.Spacing.xl)
    }

    private func claudeCodeFoundView(email: String?) -> some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            // Claude Code detected
            HStack(spacing: UIConstants.Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)

                VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                    Text("Claude Code detected!")
                        .font(.headline)

                    if let email = email {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(UIConstants.Spacing.md)
            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium))

            // Sync button
            Button {
                Task { await viewModel.syncFromClaudeCode() }
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Sync from Claude Code")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            // Manual entry fallback
            Button("Enter key manually instead") {
                viewModel.showManualEntry()
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }
    }

    private var claudeCodeNotFoundView: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            // Not found message
            HStack(spacing: UIConstants.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.title2)

                VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                    Text("Claude Code not found")
                        .font(.headline)

                    Text("Please login to Claude Code first")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(UIConstants.Spacing.md)
            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium))

            // Instructions
            instructionsView

            // Retry button
            Button {
                Task { await viewModel.retry() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Check Again")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            // Manual entry fallback
            Button("Enter session key manually") {
                viewModel.showManualEntry()
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }
    }

    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
            Text("How to login:")
                .font(.subheadline.weight(.semibold))

            VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                instructionStep(1, "Open Terminal")
                instructionStep(2, "Run: claude")
                instructionStep(3, "Login with Google/GitHub")
                instructionStep(4, "Come back here and click \"Check Again\"")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
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
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            HStack(spacing: UIConstants.Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)

                VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                    Text("Connected")
                        .font(.headline)

                    Text(masked)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(UIConstants.Spacing.md)
            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium))

            HStack {
                Button("Re-sync") {
                    Task { await viewModel.syncFromClaudeCode() }
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Disconnect") {
                    Task { await viewModel.deleteKey() }
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }

    private var loadingView: some View {
        HStack(spacing: UIConstants.Spacing.md) {
            ProgressView()
                .scaleEffect(0.8)
            Text(viewModel.state == .syncing ? "Syncing..." : "Validating...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(UIConstants.Spacing.xl)
    }

    private func successView(message: String) -> some View {
        HStack(spacing: UIConstants.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title2)
            Text(message)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(UIConstants.Spacing.md)
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium))
    }

    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            HStack(spacing: UIConstants.Spacing.md) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.title2)

                Text(message)
                    .foregroundStyle(.secondary)
                    .font(.callout)

                Spacer()
            }
            .padding(UIConstants.Spacing.md)
            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium))

            Button {
                Task { await viewModel.retry() }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var manualEntryView: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            Text("Manual Entry")
                .font(.subheadline.weight(.semibold))

            SessionKeyInputView(
                text: $viewModel.inputKey,
                placeholder: "Paste session key from browser cookies",
                isDisabled: viewModel.state == .validating,
                onSubmit: { Task { await viewModel.saveManualKey() } }
            )

            HStack {
                Button("Cancel") {
                    Task { await viewModel.cancelManualEntry() }
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Save") {
                    Task { await viewModel.saveManualKey() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSubmitManual)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("AIMeter v1.0")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .keyboardShortcut(.defaultAction)
        }
        .padding(UIConstants.Spacing.lg)
    }
}

// MARK: - Preview

#Preview("Checking") {
    SettingsView(viewModel: makePreviewViewModel())
}

@MainActor
private func makePreviewViewModel() -> SettingsViewModel {
    SettingsViewModel(
        claudeCodeSync: ClaudeCodeSyncService(),
        validateUseCase: ValidateSessionKeyUseCase(
            sessionKeyRepository: PreviewSessionKeyRepository()
        ),
        getSessionKeyUseCase: GetSessionKeyUseCase(
            sessionKeyRepository: PreviewSessionKeyRepository()
        )
    )
}

private actor PreviewSessionKeyRepository: SessionKeyRepository {
    func save(_ key: SessionKey) async throws {}
    func get() async -> SessionKey? { nil }
    func delete() async {}
    func exists() async -> Bool { false }
    func fetchOrganizationId(using key: SessionKey) async throws -> OrganizationId? {
        try OrganizationId.create("preview-org-id-12345")
    }
    func getCachedOrganizationId() async -> OrganizationId? { nil }
    func cacheOrganizationId(_ id: OrganizationId) async {}
}
