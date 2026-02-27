import AIMeterApplication
import AIMeterDomain
import AIMeterInfrastructure
import KeyboardShortcuts
import SwiftUI

/// Voice Input settings tab - Enable, API Key, Balance, Language, Shortcut
struct VoiceInputSettingsTab: View {
    var viewModel: VoiceInputViewModel
    var preferencesService: VoiceInputPreferencesService

    @State private var apiKeyInput: String = ""
    @State private var hasKey: Bool = false
    @State private var hasAccessibility: Bool = false

    private let tableName = "SettingsVoiceInput"

    var body: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            // Enable toggle
            SettingsCard(title: "Voice Input", tableName: tableName) {
                SettingsToggle(
                    title: "Speech-to-text via Deepgram",
                    description: "Press shortcut to record, release to insert text",
                    icon: "mic.fill",
                    tableName: tableName,
                    isOn: Binding(
                        get: { preferencesService.isEnabled },
                        set: { newValue in
                            Task {
                                if newValue {
                                    await viewModel.enable()
                                } else {
                                    await viewModel.disable()
                                }
                            }
                        }
                    )
                )
            }

            if preferencesService.isEnabled {
                // Accessibility warning
                if !hasAccessibility {
                    accessibilityWarningCard
                }

                // API Key
                apiKeyCard

                // Balance
                if hasKey {
                    balanceCard
                }

                // Language
                languageCard

                // Keyboard Shortcut
                shortcutCard
            }
        }
        .padding(UIConstants.Spacing.xl)
        .task {
            apiKeyInput = await viewModel.loadApiKey()
            hasKey = !apiKeyInput.isEmpty
            hasAccessibility = viewModel.checkAccessibility()
            if hasKey {
                await viewModel.fetchBalance()
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilityWarningCard: some View {
        SettingsCard(tableName: tableName) {
            VStack(spacing: UIConstants.Spacing.md) {
                HStack(spacing: UIConstants.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AccessibleColors.moderate)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accessibility permission required")
                            .font(.headline)

                        Text("Enable AIMeter in System Settings → Accessibility, then restart the app.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                SettingsButton(
                    "Open Accessibility Settings",
                    icon: "gear",
                    style: .primary,
                    tableName: tableName
                ) {
                    viewModel.openAccessibilitySettings()
                }
            }
        }
    }

    // MARK: - API Key

    private var apiKeyCard: some View {
        SettingsCard(title: "API Key", tableName: tableName) {
            VStack(spacing: UIConstants.Spacing.md) {
                if hasKey {
                    // Connected state
                    HStack(spacing: UIConstants.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AccessibleColors.success)
                            .font(.title3)

                        Text("API key saved")
                            .font(.headline)

                        Spacer()
                    }

                    Divider()

                    SecureField("Enter new API key", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: UIConstants.Spacing.sm) {
                        SettingsButton(
                            "Update",
                            icon: "arrow.triangle.2.circlepath",
                            style: .primary,
                            tableName: tableName
                        ) {
                            Task {
                                await viewModel.saveApiKey(apiKeyInput)
                                hasKey = true
                            }
                        }

                        SettingsButton(
                            "Delete",
                            icon: "trash",
                            style: .destructive,
                            tableName: tableName
                        ) {
                            Task {
                                await viewModel.deleteApiKey()
                                apiKeyInput = ""
                                hasKey = false
                            }
                        }
                    }
                } else {
                    // No key state
                    HStack(spacing: UIConstants.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AccessibleColors.moderate)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("No API key")
                                .font(.headline)

                            Text("Enter your Deepgram API key to enable voice input")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    Divider()

                    SecureField("Enter Deepgram API key", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)

                    SettingsButton(
                        "Save",
                        icon: "checkmark.circle",
                        style: .primary,
                        tableName: tableName
                    ) {
                        Task {
                            await viewModel.saveApiKey(apiKeyInput)
                            hasKey = true
                        }
                    }
                    .disabled(apiKeyInput.isEmpty)
                }

                Link(
                    "Get free API key →",
                    destination: URL(string: "https://console.deepgram.com/signup")!
                )
                .font(.caption)

                Text("Create an API key with Admin role to enable balance display")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Balance

    private var balanceCard: some View {
        SettingsCard(title: "Balance", tableName: tableName) {
            HStack {
                if viewModel.isLoadingBalance {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if let balance = viewModel.balance {
                    Label {
                        Text(balance.displayText)
                    } icon: {
                        Image(systemName: "creditcard")
                            .foregroundStyle(.blue)
                    }
                } else if let error = viewModel.balanceError {
                    Label {
                        Text(error)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(AccessibleColors.moderate)
                    }
                } else {
                    Label {
                        Text("Not loaded")
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "creditcard")
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                SettingsButton(
                    "Refresh",
                    icon: "arrow.clockwise",
                    style: .secondary,
                    tableName: tableName
                ) {
                    Task { await viewModel.fetchBalance() }
                }
            }
        }
    }

    // MARK: - Language

    private var languageCard: some View {
        SettingsCard(title: "Language", tableName: tableName) {
            HStack {
                Label {
                    Text("Transcription Language")
                } icon: {
                    Image(systemName: "globe")
                        .foregroundStyle(.blue)
                }

                Spacer()

                Picker("", selection: Binding(
                    get: { preferencesService.selectedLanguage },
                    set: { preferencesService.selectedLanguage = $0 }
                )) {
                    ForEach(TranscriptionLanguage.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()
            }
        }
    }

    // MARK: - Shortcut

    private var shortcutCard: some View {
        SettingsCard(title: "Keyboard Shortcut", tableName: tableName) {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Voice Input")
                        Text("Start/stop voice recording")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "command")
                        .foregroundStyle(.blue)
                }

                Spacer()

                KeyboardShortcuts.Recorder(for: .voiceInput)
            }
        }
    }
}
