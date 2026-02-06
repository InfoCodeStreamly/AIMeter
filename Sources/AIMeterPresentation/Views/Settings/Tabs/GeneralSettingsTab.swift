import SwiftUI
import AIMeterDomain
import AIMeterApplication
import AIMeterInfrastructure
import KeyboardShortcuts

/// General settings tab - Appearance, Language, Startup, Keyboard Shortcuts
struct GeneralSettingsTab: View {
    var launchAtLogin: LaunchAtLoginService
    @Environment(ThemeService.self) private var themeService
    @Environment(LanguageService.self) private var languageService

    private let tableName = "SettingsGeneral"
    private let languageTableName = "SettingsLanguage"

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

            // Language
            SettingsCard(title: "Language", tableName: tableName) {
                VStack(spacing: UIConstants.Spacing.sm) {
                    ForEach(languageService.availableLanguages, id: \.self) { language in
                        languageRow(language)
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

    // MARK: - Language Row

    @MainActor
    private func languageRow(_ language: AppLanguage) -> some View {
        let isSelected = languageService.selectedLanguage == language

        return Button {
            withAnimation(.easeInOut(duration: UIConstants.Animation.fast)) {
                languageService.selectedLanguage = language
            }
        } label: {
            HStack(spacing: UIConstants.Spacing.md) {
                Image(systemName: language.icon)
                    .font(.body)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if language == .system {
                        Text("Currently: \(languageService.systemLanguageName)", tableName: languageTableName, bundle: .main)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

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
