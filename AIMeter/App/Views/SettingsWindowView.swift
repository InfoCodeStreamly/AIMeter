import AIMeterInfrastructure
import AIMeterPresentation
import AppKit
import SwiftUI

/// Settings window content wrapper
struct SettingsWindowView: View {
    @State private var viewModel = DependencyContainer.shared.makeSettingsViewModel()
    let checkForUpdatesViewModel: CheckForUpdatesViewModel

    var body: some View {
        SettingsView(
            viewModel: viewModel,
            checkForUpdatesViewModel: checkForUpdatesViewModel,
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
                window.level = UIConstants.WindowLevel.settings
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
