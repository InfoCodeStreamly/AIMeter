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
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .symbolRenderingMode(.palette)
                .foregroundStyle(statusColor, .primary)

            if let primary = viewModel.primaryUsage {
                Text(primary.percentageText)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .monospacedDigit()
            }
        }
    }

    private var statusIcon: String {
        if viewModel.hasCriticalUsage {
            return "exclamationmark.circle.fill"
        }
        return "gauge.with.dots.needle.33percent"
    }

    private var statusColor: Color {
        if viewModel.hasCriticalUsage {
            return .red
        }
        if let primary = viewModel.primaryUsage {
            return primary.color
        }
        return .secondary
    }
}
