import SwiftUI

/// Card view for individual usage metric
struct UsageCardView: View {
    let data: UsageDisplayData
    let isPrimary: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(
                        Color.gray.opacity(0.2),
                        lineWidth: isPrimary ? 6 : 4
                    )

                Circle()
                    .trim(from: 0, to: CGFloat(data.percentage) / 100)
                    .stroke(
                        data.color,
                        style: StrokeStyle(
                            lineWidth: isPrimary ? 6 : 4,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: data.percentage)

                Text(data.percentageText)
                    .font(isPrimary ? .system(size: 14, weight: .bold) : .system(size: 11, weight: .semibold))
                    .foregroundStyle(data.color)
            }
            .frame(width: isPrimary ? 48 : 36, height: isPrimary ? 48 : 36)

            // Labels
            VStack(alignment: .leading, spacing: 2) {
                Text(data.title)
                    .font(isPrimary ? .subheadline.weight(.semibold) : .caption.weight(.medium))
                    .foregroundStyle(.primary)

                Text(data.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Reset time
            VStack(alignment: .trailing, spacing: 2) {
                Image(systemName: data.icon)
                    .font(.system(size: 10))
                    .foregroundStyle(data.color)

                Text(data.countdown)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, isPrimary ? 12 : 8)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
    }
}

#Preview {
    VStack(spacing: 8) {
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
    .frame(width: 280)
}
