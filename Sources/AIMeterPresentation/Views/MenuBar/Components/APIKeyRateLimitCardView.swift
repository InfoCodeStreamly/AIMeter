import SwiftUI

/// Card view for displaying personal API key rate limits
struct APIKeyRateLimitCardView: View {
    let data: APIKeyRateLimitDisplayData

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
            // Header
            HStack {
                Label {
                    Text("Rate Limits", tableName: "MenuBar", bundle: .main)
                        .font(.subheadline.weight(.semibold))
                } icon: {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                        .foregroundStyle(.blue)
                }

                Spacer()

                if !data.nextResetLabel.isEmpty {
                    Text(data.nextResetLabel)
                        .font(.system(size: 9).monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }

            // Rows
            rateLimitRow(
                icon: "arrow.up.arrow.down",
                label: "RPM",
                subtitle: "Requests / min",
                value: data.requestsRemaining,
                percent: data.requestsPercent
            )

            rateLimitRow(
                icon: "arrow.down",
                label: "Input TPM",
                subtitle: "Input tokens / min",
                value: data.inputTokensRemaining,
                percent: data.inputTokensPercent
            )

            rateLimitRow(
                icon: "arrow.up",
                label: "Output TPM",
                subtitle: "Output tokens / min",
                value: data.outputTokensRemaining,
                percent: data.outputTokensPercent
            )
        }
        .padding(UIConstants.Spacing.md)
        .glassCard()
    }

    // MARK: - Row

    private func rateLimitRow(icon: String, label: String, subtitle: String, value: String, percent: Int) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: UIConstants.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .frame(width: 12)

                VStack(alignment: .leading, spacing: 0) {
                    Text(label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Text(value)
                    .font(.caption.monospacedDigit().weight(.medium))
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.quaternary)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForPercent(percent))
                        .frame(width: geometry.size.width * CGFloat(percent) / 100.0)
                }
            }
            .frame(height: 3)
        }
    }

    private func colorForPercent(_ percent: Int) -> Color {
        switch percent {
        case 80...:
            return AccessibleColors.critical
        case 50...:
            return AccessibleColors.moderate
        default:
            return AccessibleColors.success
        }
    }
}
