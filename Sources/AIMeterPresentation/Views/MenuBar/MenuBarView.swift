import SwiftUI
import AIMeterDomain
import AIMeterApplication
import AIMeterInfrastructure
import Sparkle

/// Main menu bar popover view
public struct MenuBarView: View {
    @Bindable var viewModel: UsageViewModel
    let updater: SPUUpdater
    @Environment(\.openWindow) private var openWindow
    @State private var isRefreshing = false

    public init(viewModel: UsageViewModel, updater: SPUUpdater) {
        self.viewModel = viewModel
        self.updater = updater
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(
                lastUpdated: viewModel.lastUpdatedText,
                isRefreshing: isRefreshing,
                onRefresh: {
                    withAnimation(.easeInOut(duration: UIConstants.Animation.fast)) {
                        isRefreshing = true
                    }
                    viewModel.refresh()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: UIConstants.Animation.fast)) {
                            isRefreshing = false
                        }
                    }
                },
                onCopy: { viewModel.copyToClipboard() },
                onSettings: { openWindow(id: "settings") }
            )

            Divider()
                .padding(.horizontal, UIConstants.Spacing.md)

            // Content
            Group {
                switch viewModel.state {
                case .loading:
                    loadingView

                case .loaded:
                    usageListView

                case .error(let message):
                    errorView(message: message)

                case .needsSetup:
                    setupView
                }
            }
            .frame(maxWidth: .infinity)

            Divider()
                .padding(.horizontal, UIConstants.Spacing.md)

            // Footer
            FooterView(onQuit: { NSApplication.shared.terminate(nil) })
        }
        .frame(width: UIConstants.MenuBar.width)
        .background(.ultraThinMaterial)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: UIConstants.Spacing.md) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading...", tableName: "Localizable", bundle: .main)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 120)
    }

    private var usageListView: some View {
        VStack(spacing: UIConstants.Spacing.sm) {
            // Primary usage (session)
            if let primary = viewModel.primaryUsage {
                UsageCardView(data: primary, isPrimary: true)
            }

            // Secondary usages (weekly)
            ForEach(viewModel.secondaryUsages) { usage in
                UsageCardView(data: usage, isPrimary: false)
            }

            // Extra usage (pay-as-you-go) if enabled
            if let extraUsage = viewModel.extraUsage {
                ExtraUsageCardView(data: extraUsage)
            }

            // Usage history chart
            if !viewModel.usageHistory.isEmpty {
                UsageChartView(history: viewModel.usageHistory) {
                    openWindow(id: "usage-detail")
                }
            }
        }
        .padding(UIConstants.Spacing.md)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: UIConstants.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.orange)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.refresh()
            } label: {
                Text("Retry", tableName: "Localizable", bundle: .main)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .frame(height: 120)
    }

    private var setupView: some View {
        VStack(spacing: UIConstants.Spacing.md) {
            Image(systemName: "key")
                .font(.title2)
                .foregroundStyle(.blue)

            Text("Session key required", tableName: "MenuBar", bundle: .main)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                openWindow(id: "settings")
            } label: {
                Text("Open Settings", tableName: "Localizable", bundle: .main)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .frame(height: 120)
    }
}

// MARK: - Preview Helpers

private actor PreviewUsageRepository: UsageRepository {
    func fetchUsage() async throws -> [UsageEntity] {
        UsageEntity.allDefaults()
    }

    func getCachedUsage() async -> [UsageEntity] {
        UsageEntity.allDefaults()
    }

    func cacheUsage(_ entities: [UsageEntity]) async {}

    func getExtraUsage() async -> ExtraUsageEntity? {
        nil
    }
}

private actor PreviewSessionKeyRepository: SessionKeyRepository {
    func save(_ key: SessionKey) async throws {}
    func get() async -> SessionKey? { try? SessionKey.create("preview-session-key-12345") }
    func delete() async {}
    func exists() async -> Bool { true }
    func validateToken(_ token: String) async throws {}
}
