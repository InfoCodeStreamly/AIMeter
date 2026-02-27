import AIMeterApplication
import AIMeterDomain
import KeyboardShortcuts
import SwiftUI

/// General settings tab - Appearance, Language, Startup, Keyboard Shortcuts
struct GeneralSettingsTab: View {
    var launchAtLogin: any LaunchAtLoginServiceProtocol
    @Environment(\.themeService) private var themeService
    @Environment(\.languageService) private var languageService

    private let tableName = "SettingsGeneral"

    var body: some View {
        VStack(spacing: UIConstants.Spacing.lg) {
            // Appearance
            if let themeService {
                SettingsCard(title: "Appearance", tableName: tableName) {
                    HStack {
                        Label {
                            Text("Theme", tableName: tableName, bundle: .main)
                        } icon: {
                            Image(systemName: "paintbrush")
                                .foregroundStyle(.blue)
                        }

                        Spacer()

                        Picker("", selection: Binding(
                            get: { themeService.selectedTheme },
                            set: { themeService.selectedTheme = $0 }
                        )) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Label(theme.displayName, systemImage: theme.icon)
                                    .tag(theme)
                            }
                        }
                        .pickerStyle(.menu)
                        .fixedSize()
                    }
                }
            }

            // Language
            if let languageService {
                SettingsCard(title: "Language", tableName: tableName) {
                    HStack {
                        Label {
                            Text("Language", tableName: tableName, bundle: .main)
                        } icon: {
                            Image(systemName: "globe")
                                .foregroundStyle(.blue)
                        }

                        Spacer()

                        Picker("", selection: Binding(
                            get: { languageService.selectedLanguage },
                            set: { languageService.selectedLanguage = $0 }
                        )) {
                            ForEach(languageService.availableLanguages, id: \.self) { language in
                                Text(language.displayName)
                                    .tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                        .fixedSize()
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
                            Text(
                                "Open or close the usage menu", tableName: tableName, bundle: .main
                            )
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
}
