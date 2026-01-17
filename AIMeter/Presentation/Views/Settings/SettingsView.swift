import SwiftUI
import AppKit

/// Settings window view
struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    var launchAtLogin: LaunchAtLoginService
    var notificationPreferences: NotificationPreferencesService
    var appInfo: AppInfoService
    var checkForUpdatesUseCase: CheckForUpdatesUseCase
    @Environment(\.dismiss) private var dismiss

    // Update state
    @State private var isCheckingUpdates = false
    @State private var updateResult: UpdateCheckResult?

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
                generalSection
                notificationsSection
                connectionSection
                aboutSection
            }
            .padding(UIConstants.Spacing.xl)
        }
    }

    // MARK: - General Section

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            Label("General", systemImage: "gearshape")
                .font(.subheadline.weight(.semibold))

            Toggle(isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { _ in launchAtLogin.toggle() }
            )) {
                HStack {
                    Image(systemName: "power")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch at Login")
                        Text("Start AIMeter when you log in")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .toggleStyle(.switch)
            .padding(UIConstants.Spacing.md)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium))
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            Label("Notifications", systemImage: "bell")
                .font(.subheadline.weight(.semibold))

            Toggle(isOn: Binding(
                get: { notificationPreferences.isEnabled },
                set: { notificationPreferences.isEnabled = $0 }
            )) {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Usage Alerts")
                        Text("Notify at 80% and 95% usage")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .toggleStyle(.switch)
            .padding(UIConstants.Spacing.md)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium))
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

            case .syncing:
                loadingView

            case .success(let message):
                successView(message: message)

            case .error(let message):
                errorView(message: message)
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            Label("About", systemImage: "info.circle")
                .font(.subheadline.weight(.semibold))

            VStack(spacing: UIConstants.Spacing.md) {
                // App info
                HStack {
                    Image(systemName: "app.badge")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appInfo.appName)
                            .font(.headline)
                        Text(appInfo.fullVersion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider()

                // Author
                HStack {
                    Text("Made by")
                        .foregroundStyle(.secondary)
                    Text(appInfo.author)
                        .fontWeight(.medium)
                    Spacer()
                }
                .font(.caption)

                // GitHub link
                Button {
                    openGitHub()
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("View on GitHub")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                // Check for updates
                Button {
                    Task { await checkForUpdates() }
                } label: {
                    HStack {
                        if isCheckingUpdates {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: updateButtonIcon)
                        }
                        Text(updateButtonText)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isCheckingUpdates)
            }
            .padding(UIConstants.Spacing.md)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium))
        }
    }

    // MARK: - Update Helpers

    private var updateButtonText: String {
        if isCheckingUpdates {
            return "Checking..."
        }
        guard let result = updateResult else {
            return "Check for Updates"
        }
        switch result {
        case .upToDate:
            return "Up to Date"
        case .updateAvailable(let version, _):
            return "Update Available: v\(version)"
        case .error:
            return "Check for Updates"
        }
    }

    private var updateButtonIcon: String {
        guard let result = updateResult else {
            return "arrow.triangle.2.circlepath"
        }
        switch result {
        case .upToDate:
            return "checkmark.circle"
        case .updateAvailable:
            return "arrow.down.circle"
        case .error:
            return "arrow.triangle.2.circlepath"
        }
    }

    private func checkForUpdates() async {
        isCheckingUpdates = true
        updateResult = nil

        updateResult = await checkForUpdatesUseCase.execute()

        isCheckingUpdates = false

        // If update available, offer to open release page
        if case .updateAvailable(_, let url) = updateResult {
            NSWorkspace.shared.open(url)
        }
    }

    private func openGitHub() {
        if let url = URL(string: APIConstants.GitHub.repoURL) {
            NSWorkspace.shared.open(url)
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

            // Re-sync button
            Button {
                Task { await viewModel.syncFromClaudeCode() }
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Re-sync")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            // Disconnect button
            Button(role: .destructive) {
                Task { await viewModel.deleteKey() }
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Disconnect")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private var loadingView: some View {
        HStack(spacing: UIConstants.Spacing.md) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Syncing...")
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

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text(appInfo.fullVersion)
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
    SettingsView(
        viewModel: makePreviewViewModel(),
        launchAtLogin: LaunchAtLoginService(),
        notificationPreferences: NotificationPreferencesService(),
        appInfo: AppInfoService(),
        checkForUpdatesUseCase: makePreviewCheckForUpdatesUseCase()
    )
}

@MainActor
private func makePreviewCheckForUpdatesUseCase() -> CheckForUpdatesUseCase {
    CheckForUpdatesUseCase(
        appInfoService: AppInfoService(),
        gitHubUpdateService: GitHubUpdateService()
    )
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
        ),
        credentialsRepository: PreviewOAuthCredentialsRepository()
    )
}

private actor PreviewSessionKeyRepository: SessionKeyRepository {
    func save(_ key: SessionKey) async throws {}
    func get() async -> SessionKey? { nil }
    func delete() async {}
    func exists() async -> Bool { false }
    func validateToken(_ token: String) async throws {}
}

private actor PreviewOAuthCredentialsRepository: OAuthCredentialsRepository {
    func getOAuthCredentials() async -> OAuthCredentials? { nil }
    func saveOAuthCredentials(_ credentials: OAuthCredentials) async throws {}
    func updateClaudeCodeKeychain(_ credentials: OAuthCredentials) async throws {}
}
