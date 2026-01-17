import SwiftUI

/// Card view for individual usage metric with gradient progress bar
struct UsageCardView: View {
    let data: UsageDisplayData
    let isPrimary: Bool

    var body: some View {
        VStack(spacing: isPrimary ? 12 : 8) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.title)
                        .font(.system(size: isPrimary ? 13 : 11, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(data.subtitle)
                        .font(.system(size: isPrimary ? 10 : 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status + Percentage
                HStack(spacing: 4) {
                    Image(systemName: data.icon)
                        .font(.system(size: isPrimary ? 12 : 10, weight: .medium))
                        .foregroundStyle(data.color)

                    Text(data.percentageText)
                        .font(.system(size: isPrimary ? 16 : 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(data.color)
                }
            }

            // Gradient progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: UIConstants.ProgressBar.cornerRadius)
                        .fill(Color.secondary.opacity(0.15))

                    // Fill with gradient
                    RoundedRectangle(cornerRadius: UIConstants.ProgressBar.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [data.color, data.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(CGFloat(data.percentage) / 100, 1.0))
                        .animation(.easeInOut(duration: UIConstants.Animation.slow), value: data.percentage)
                }
            }
            .frame(height: UIConstants.ProgressBar.height)

            // Reset time
            HStack {
                Spacer()
                Text("Resets \(data.resetTimeText)")
                    .font(.system(size: isPrimary ? 9 : 8, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(isPrimary ? 16 : 12)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium))
        )
    }
}

#Preview {
    VStack(spacing: UIConstants.Spacing.md) {
        UsageCardView(
            data: UsageDisplayData(
                from: UsageEntity(
                    type: .session,
                    percentage: .clamped(28),
                    resetTime: .defaultSession
                )
            ),
            isPrimary: true
        )

        HStack(spacing: UIConstants.Spacing.md) {
            UsageCardView(
                data: UsageDisplayData(
                    from: UsageEntity(
                        type: .weekly,
                        percentage: .clamped(55),
                        resetTime: .defaultWeekly
                    )
                ),
                isPrimary: false
            )

            UsageCardView(
                data: UsageDisplayData(
                    from: UsageEntity(
                        type: .sonnet,
                        percentage: .clamped(2),
                        resetTime: .defaultWeekly
                    )
                ),
                isPrimary: false
            )
        }
    }
    .padding()
    .frame(width: UIConstants.MenuBar.width)
    .background(.ultraThinMaterial)
}
