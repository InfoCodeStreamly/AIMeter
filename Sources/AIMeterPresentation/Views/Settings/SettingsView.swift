import AIMeterApplication
import AIMeterDomain
import AppKit
import SwiftUI

/// Settings tab identifiers
enum SettingsTab: CaseIterable {
    case general
    case connection
    case voiceInput
    case about

    var titleKey: String {
        switch self {
        case .general: return "General"
        case .connection: return "Connection"
        case .voiceInput: return "Voice Input"
        case .about: return "About"
        }
    }

    var tableName: String {
        switch self {
        case .general: return "SettingsGeneral"
        case .connection: return "SettingsConnection"
        case .voiceInput: return "SettingsVoiceInput"
        case .about: return "SettingsAbout"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .connection: return "link"
        case .voiceInput: return "mic"
        case .about: return "info.circle"
        }
    }
}

/// Settings window view with toolbar-style tabs
public struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    var checkForUpdatesViewModel: CheckForUpdatesViewModel
    var launchAtLogin: any LaunchAtLoginServiceProtocol
    var notificationPreferences: any NotificationPreferencesProtocol
    var appInfo: any AppInfoServiceProtocol
    var voiceInputViewModel: VoiceInputViewModel?
    var voiceInputPreferences: (any VoiceInputPreferencesProtocol)?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: SettingsTab = .general
    @State private var contentHeight: CGFloat = 0

    public init(
        viewModel: SettingsViewModel,
        checkForUpdatesViewModel: CheckForUpdatesViewModel,
        launchAtLogin: any LaunchAtLoginServiceProtocol,
        notificationPreferences: any NotificationPreferencesProtocol,
        appInfo: any AppInfoServiceProtocol,
        voiceInputViewModel: VoiceInputViewModel? = nil,
        voiceInputPreferences: (any VoiceInputPreferencesProtocol)? = nil
    ) {
        self.viewModel = viewModel
        self.checkForUpdatesViewModel = checkForUpdatesViewModel
        self.launchAtLogin = launchAtLogin
        self.notificationPreferences = notificationPreferences
        self.appInfo = appInfo
        self.voiceInputViewModel = voiceInputViewModel
        self.voiceInputPreferences = voiceInputPreferences
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar-style tab bar
            tabBar
                .padding(.top, UIConstants.Spacing.sm)

            Divider()
                .padding(.top, UIConstants.Spacing.sm)

            // Tab content — measured and animated
            tabContent
                .frame(maxWidth: .infinity, alignment: .top)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    contentHeight = height
                }
                .frame(height: contentHeight, alignment: .top)
                .clipped()
        }
        .frame(width: UIConstants.Settings.windowWidth)
        .animation(.easeInOut(duration: 0.2), value: contentHeight)
        .background(.regularMaterial)
        .modifier(WindowResizeAnchorModifier())
        .task {
            await viewModel.onAppear()
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: UIConstants.Spacing.sm) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, UIConstants.Spacing.xl)
    }

    private func tabButton(for tab: SettingsTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))
                    .frame(height: 24)

                Text(LocalizedStringKey(tab.titleKey), tableName: tab.tableName, bundle: .main)
                    .font(.caption)
            }
            .foregroundStyle(selectedTab == tab ? .blue : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, UIConstants.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassTab(isSelected: selectedTab == tab)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .general:
            GeneralSettingsTab(
                launchAtLogin: launchAtLogin
            )

        case .connection:
            ConnectionSettingsTab(
                viewModel: viewModel,
                notificationPreferences: notificationPreferences
            )

        case .voiceInput:
            if let voiceVM = voiceInputViewModel, let voicePrefs = voiceInputPreferences {
                VoiceInputSettingsTab(
                    viewModel: voiceVM,
                    preferencesService: voicePrefs
                )
            }

        case .about:
            AboutSettingsTab(
                checkForUpdatesViewModel: checkForUpdatesViewModel,
                appInfo: appInfo
            )
        }
    }
}

// MARK: - Window Resize Anchor

private struct WindowResizeAnchorModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
            if #available(macOS 26.0, *) {
                content.windowResizeAnchor(.topLeading)
            } else {
                content
            }
        #else
            content
        #endif
    }
}

// MARK: - Preview

private actor PreviewClaudeCodeSyncService: ClaudeCodeSyncServiceProtocol {
    func hasCredentials() async -> Bool { false }
    func getSubscriptionInfo() async -> (type: String, email: String?)? { nil }
    func extractOAuthCredentials() async throws -> OAuthCredentials {
        throw SyncError.noCredentialsFound
    }
    func updateCredentials(_ credentials: OAuthCredentials) async throws {}
}

@MainActor
private func makePreviewViewModel() -> SettingsViewModel {
    SettingsViewModel(
        claudeCodeSync: PreviewClaudeCodeSyncService(),
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
