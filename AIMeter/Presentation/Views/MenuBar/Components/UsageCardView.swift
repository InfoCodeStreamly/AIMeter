import SwiftUI

/// Card view for individual usage metric
struct UsageCardView: View {
    let data: UsageDisplayData
    let isPrimary: Bool

    var body: some View {
        HStack(spacing: UIConstants.Spacing.md) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(
                        Color.gray.opacity(0.2),
                        lineWidth: isPrimary ? UIConstants.ProgressCircle.primaryLineWidth : UIConstants.ProgressCircle.secondaryLineWidth
                    )

                Circle()
                    .trim(from: 0, to: CGFloat(data.percentage) / 100)
                    .stroke(
                        data.color,
                        style: StrokeStyle(
                            lineWidth: isPrimary ? UIConstants.ProgressCircle.primaryLineWidth : UIConstants.ProgressCircle.secondaryLineWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: UIConstants.Animation.slow), value: data.percentage)

                Text(data.percentageText)
                    .font(isPrimary ? .system(size: 14, weight: .bold) : .system(size: 11, weight: .semibold))
                    .foregroundStyle(data.color)
            }
            .frame(
                width: isPrimary ? UIConstants.ProgressCircle.primarySize : UIConstants.ProgressCircle.secondarySize,
                height: isPrimary ? UIConstants.ProgressCircle.primarySize : UIConstants.ProgressCircle.secondarySize
            )

            // Labels
            VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                Text(data.title)
                    .font(isPrimary ? .subheadline.weight(.semibold) : .caption.weight(.medium))
                    .foregroundStyle(.primary)

                Text(data.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Reset time
            VStack(alignment: .trailing, spacing: UIConstants.Spacing.xs) {
                Image(systemName: data.icon)
                    .font(.system(size: 10))
                    .foregroundStyle(data.color)

                Text(data.resetTimeText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, UIConstants.Spacing.md)
        .padding(.vertical, isPrimary ? UIConstants.Spacing.md : UIConstants.Spacing.sm)
    }
}

#Preview {
    VStack(spacing: UIConstants.Spacing.sm) {
        UsageCardView(
            data: UsageDisplayData(
                from: UsageEntity(
                    type: .session,
                    percentage: .clamped(65),
                    resetTime: .defaultSession
                )
            ),
            isPrimary: true
        )

        UsageCardView(
            data: UsageDisplayData(
                from: UsageEntity(
                    type: .opus,
                    percentage: .clamped(23),
                    resetTime: .defaultWeekly
                )
            ),
            isPrimary: false
        )
    }
    .padding()
    .frame(width: UIConstants.MenuBar.width)
    .background(.ultraThinMaterial)
}
