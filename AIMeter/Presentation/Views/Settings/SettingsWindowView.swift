import SwiftUI
import Sparkle
import AppKit

/// Settings window content wrapper
struct SettingsWindowView: View {
    @State private var viewModel = DependencyContainer.shared.makeSettingsViewModel()
    let updater: SPUUpdater

    var body: some View {
        SettingsView(
            viewModel: viewModel,
            updater: updater,
            launchAtLogin: DependencyContainer.shared.launchAtLoginService,
            notificationPreferences: DependencyContainer.shared.notificationPreferencesService,
            appInfo: DependencyContainer.shared.appInfoService
        )
        .background(WindowAccessor())
    }
}

// MARK: - Window Level Helper

/// Makes the window float above other windows
private struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.level = .floating
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
