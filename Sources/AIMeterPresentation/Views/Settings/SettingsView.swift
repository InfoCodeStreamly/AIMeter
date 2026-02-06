import AIMeterApplication
import AIMeterDomain
import AIMeterInfrastructure
import AppKit
import Sparkle
import SwiftUI

/// Settings tab identifiers with localization keys
enum SettingsTab: CaseIterable {
    case general
    case connection
    case about

    /// Localization key for the tab title
    var titleKey: String {
        switch self {
        case .general: return "General"
        case .connection: return "Connection"
        case .about: return "About"
        }
    }

    /// Localization table name
    var tableName: String {
        switch self {
        case .general: return "SettingsGeneral"
        case .connection: return "SettingsConnection"
        case .about: return "SettingsAbout"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .connection: return "link"
        case .about: return "info.circle"
        }
    }
}

/// Settings window view with toolbar-style tabs
public struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    let updater: SPUUpdater
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    var launchAtLogin: LaunchAtLoginService
    var notificationPreferences: NotificationPreferencesService
    var appInfo: AppInfoService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: SettingsTab = .general
    @State private var contentHeight: CGFloat = 0

    public init(
        viewModel: SettingsViewModel,
        updater: SPUUpdater,
        launchAtLogin: LaunchAtLoginService,
        notificationPreferences: NotificationPreferencesService,
        appInfo: AppInfoService
    ) {
        self.viewModel = viewModel
        self.updater = updater
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
        self.launchAtLogin = launchAtLogin
        self.notificationPreferences = notificationPreferences
        self.appInfo = appInfo
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

    // MARK: - Tab Bar (TG Pro style)

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, UIConstants.Spacing.lg)
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

        case .about:
            AboutSettingsTab(
                updater: updater,
                checkForUpdatesViewModel: checkForUpdatesViewModel,
                appInfo: appInfo
            )
        }
    }
}

// MARK: - Window Resize Anchor

private struct WindowResizeAnchorModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.windowResizeAnchor(.topLeading)
        } else {
            content
        }
    }
}

// MARK: - Preview

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
