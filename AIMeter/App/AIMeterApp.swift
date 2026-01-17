import SwiftUI

@main
struct AIMeterApp: App {
    @State private var viewModel = DependencyContainer.shared.makeUsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarLabel: some View {
        Text(viewModel.menuBarText)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .monospacedDigit()
    }
}
