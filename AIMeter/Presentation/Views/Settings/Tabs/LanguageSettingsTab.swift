import SwiftUI

/// Language settings tab - App language selection
struct LanguageSettingsTab: View {
    @Environment(LanguageService.self) private var languageService

    var body: some View {
        ScrollView {
            VStack(spacing: UIConstants.Spacing.lg) {
                // Language selection card
                SettingsCard(title: String(localized: "App Language")) {
                    VStack(spacing: UIConstants.Spacing.sm) {
                        ForEach(languageService.availableLanguages, id: \.self) { language in
                            languageRow(language)
                        }
                    }
                }

                // Note about system language
                SettingsCard(
                    footer: String(localized: "When set to System Default, the app follows your macOS language preferences.")
                ) {
                    EmptyView()
                }

                Spacer()
            }
            .padding(UIConstants.Spacing.xl)
        }
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
                // Icon
                Image(systemName: language.icon)
                    .font(.body)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 24)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if language == .system {
                        Text("Currently: \(languageService.systemLanguageName)", tableName: "Localizable", comment: "Shows current system language")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Checkmark
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

#Preview {
    LanguageSettingsTab()
        .environment(LanguageService())
        .frame(width: UIConstants.Settings.windowWidth)
        .background(.ultraThinMaterial)
}
