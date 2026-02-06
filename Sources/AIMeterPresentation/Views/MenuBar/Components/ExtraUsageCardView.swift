import AIMeterDomain
import SwiftUI

/// Card view for displaying extra usage (pay-as-you-go) data
struct ExtraUsageCardView: View {
    let data: ExtraUsageDisplayData

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Extra Usage", tableName: "MenuBar", bundle: .main)
                        .font(.subheadline.weight(.semibold))
                    Text("Pay-as-you-go", tableName: "MenuBar", bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: data.icon)
                        .foregroundStyle(data.color)
                    Text(data.percentageText)
                        .font(.title3.weight(.bold).monospacedDigit())
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: UIConstants.ProgressBar.cornerRadius)
                        .fill(Color.secondary.opacity(0.2))

                    // Filled portion with gradient
                    RoundedRectangle(cornerRadius: UIConstants.ProgressBar.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [data.color, data.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(data.percentage) / 100)
                        .animation(
                            .easeInOut(duration: UIConstants.Animation.slow), value: data.percentage
                        )
                }
            }
            .frame(height: UIConstants.ProgressBar.height)

            // Credits info
            HStack {
                Label {
                    Text(data.usageSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "creditcard")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(data.remainingCredits) remaining", tableName: "MenuBar", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(UIConstants.Spacing.md)
        .glassCard()
    }
}

// MARK: - Preview

#Preview {
    ExtraUsageCardView(
        data: ExtraUsageDisplayData(
            isEnabled: true,
            usedCredits: "$12.50",
            monthlyLimit: "$100.00",
            remainingCredits: "$87.50",
            percentage: 12,
            status: .safe
        )
    )
    .padding()
    .frame(width: 300)
}
